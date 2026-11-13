#!/bin/sh
# build-node-addon.sh - build one self-contained Node-API prebuild for the platform it runs on.
#
# Run from the root of a repository that has a Node-API addon at npm/native/<stem>_napi.c, after
# the repository's own libraries were built (lib/lib<stem>.so|.dylib|.dll) and its dependencies
# were installed. Node-API is ABI-stable, so the result loads on every Node version of the same
# OS / CPU / libc.
#
# Usage:  build-node-addon.sh <outdir>
# Env:    NODE_ADDON_LIBS    linker flags (default: the -l flags of the root *.pc Libs: line, else -l<stem>)
#         NODE_ADDON_PREFIX  install prefix of the dependencies (default: brew prefix, $PREFIX or /usr)
#
# Output: <outdir>/node-prebuild-<key>.tar.gz holding prebuilds/<key>/<stem>.node plus every
#         non-system shared library it needs, resolved relative to the addon (rpath $ORIGIN on
#         Linux, @loader_path on macOS, the addon directory on Windows).
#         <key> is <os>-<cpu>[-musl] with os in linux|darwin|win32 and cpu in x64|arm64: the exact
#         directory name @tty-pt/stele's loadNativeAddon searches (prebuilds/<platform>-<arch>/).
#         When $GITHUB_OUTPUT is set, "key=<key>" is written to it.

set -eu

outdir=${1:?usage: build-node-addon.sh <outdir>}

# Node-API headers and the Windows import definitions, pinned and checksummed.
HDR_VER=1.9.0
HDR_SHA256=6cbfac49542194ae2c8f1dee5fa2dc00d66bec9cbf3b59e3a4e5f16d14eb0d19
HDR_URL="https://registry.npmjs.org/node-api-headers/-/node-api-headers-$HDR_VER.tgz"

die() { echo "build-node-addon: $*" >&2; exit 1; }

# ---- addon source ----------------------------------------------------------------------------
src=
for f in npm/native/*_napi.c; do
	[ -f "$f" ] || continue
	[ -z "$src" ] || die "more than one npm/native/*_napi.c; not supported yet"
	src=$f
done
[ -n "$src" ] || die "no npm/native/*_napi.c in $(pwd)"
base=${src##*/}
stem=${base%_napi.c}

# ---- platform key ----------------------------------------------------------------------------
case "$(uname -s)" in
	Linux) os=linux ;;
	Darwin) os=darwin ;;
	MINGW*|MSYS*|CYGWIN*) os=win32 ;;
	*) die "unsupported OS $(uname -s)" ;;
esac
case "$(uname -m)" in
	x86_64|amd64) cpu=x64 ;;
	aarch64|arm64) cpu=arm64 ;;
	*) die "unsupported CPU $(uname -m)" ;;
esac
key=$os-$cpu
if [ "$os" = linux ]; then
	for m in /lib/ld-musl-* /usr/lib/ld-musl-*; do
		if [ -e "$m" ]; then key=$key-musl; break; fi
	done
fi

# ---- prefix and flags ------------------------------------------------------------------------
prefix=${NODE_ADDON_PREFIX:-}
if [ -z "$prefix" ] && [ "$os" = darwin ] && command -v brew >/dev/null 2>&1; then
	prefix=$(brew --prefix)
fi
prefix=${prefix:-${PREFIX:-/usr}}
# Linker flags: the -l entries of the repository's own pkg-config file (what its consumers link),
# unless overridden. -L entries are dropped: the build adds ./lib and the prefix itself.
libs=${NODE_ADDON_LIBS:-}
if [ -z "$libs" ]; then
	for pc in ./*.pc; do
		[ -f "$pc" ] || continue
		cr=$(printf '\r')
		while IFS= read -r line; do
			line=${line%"$cr"} # Windows checkouts convert .pc files to CRLF
			case "$line" in
				Libs:*)
					for w in ${line#Libs:}; do
						case "$w" in -l*) libs="$libs $w" ;; esac
					done
					;;
			esac
		done < "$pc"
		break
	done
	# The repository's own library, even if its .pc forgot to list it (libislet's does).
	own=$(basename "$(pwd)")
	own=${own#lib}
	for ext in so dylib dll; do
		if [ -f "lib/lib$own.$ext" ]; then
			case " $libs " in *" -l$own "*) ;; *) libs="-l$own $libs" ;; esac
			break
		fi
	done
	[ -n "$libs" ] || libs=-l$stem
fi
if [ "$os" = win32 ]; then cc=${CC:-gcc}; else cc=${CC:-cc}; fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
stage=$work/stage
mkdir -p "$stage" "$outdir"

echo "== node addon: $stem  platform: $key  prefix: $prefix"

# ---- headers ---------------------------------------------------------------------------------
if command -v curl >/dev/null 2>&1; then
	curl -fsSL "$HDR_URL" -o "$work/headers.tgz"
else
	wget -q "$HDR_URL" -O "$work/headers.tgz"
fi
if command -v sha256sum >/dev/null 2>&1; then
	got=$(sha256sum "$work/headers.tgz")
else
	got=$(shasum -a 256 "$work/headers.tgz")
fi
got=${got%% *}
[ "$got" = "$HDR_SHA256" ] || die "node-api-headers checksum mismatch: $got"
tar -xzf "$work/headers.tgz" -C "$work"
inc=$work/package/include
def=$work/package/def

cflags="-O2 -DNODE_GYP_MODULE_NAME=$stem -DBUILDING_NODE_EXTENSION -I$inc -Iinclude -I$prefix/include"
libdirs="-L./lib -L$prefix/lib"
out=$stage/$stem.node

# ---- build -----------------------------------------------------------------------------------
case "$os" in
linux)
	# DT_RPATH (not RUNPATH) is inherited by the libraries the addon loads, so bundled
	# libraries find each other next to the addon.
	# shellcheck disable=SC2086
	$cc $cflags -fPIC -shared "$src" $libdirs \
		-Wl,-rpath-link,"$prefix/lib" -Wl,-rpath-link,./lib $libs \
		-Wl,--disable-new-dtags -Wl,-rpath,'$ORIGIN' -o "$out"
	;;
darwin)
	# shellcheck disable=SC2086
	$cc $cflags -fPIC -shared -undefined dynamic_lookup "$src" $libdirs $libs \
		-Wl,-rpath,@loader_path -o "$out"
	;;
win32)
	dlltool -d "$def/js_native_api.def" -l "$work/libnode_js.a"
	dlltool -d "$def/node_api.def" -l "$work/libnode_api.a"
	# A repository may build both lib<x>.a and lib<x>.dll; ld prefers the .a for -l<x>, which would
	# bake the library in and leave its dependencies unresolved. Link the freshly built DLL itself.
	win_libs=
	for w in $libs; do
		case "$w" in
			-l*) n=${w#-l}; if [ -f "lib/lib$n.dll" ]; then w=lib/lib$n.dll; fi ;;
		esac
		win_libs="$win_libs $w"
	done
	# shellcheck disable=SC2086
	$cc $cflags -shared "$src" $libdirs $win_libs -L"$work" -lnode_api -lnode_js -o "$out"
	;;
esac

# ---- bundle the non-system shared libraries --------------------------------------------------
is_system_linux() {
	case "$1" in
		libc.so.*|libm.so.*|libdl.so.*|libpthread.so.*|librt.so.*|libutil.so.*|libresolv.so.*) return 0 ;;
		libnsl.so.*|libgcc_s.so.*|libstdc++.so.*|ld-linux*|ld-musl*|linux-vdso*) return 0 ;;
	esac
	return 1
}

bundle_linux() {
	export LD_LIBRARY_PATH="$PWD/lib:$prefix/lib:${LD_LIBRARY_PATH:-}"
	changed=1
	while [ "$changed" = 1 ]; do
		changed=0
		for f in "$stage"/*; do
			ldd "$f" > "$work/deps" 2>/dev/null || true
			while read -r soname arrow path rest; do
				[ "$arrow" = "=>" ] || continue
				case "$path" in /*) ;; *) continue ;; esac
				if is_system_linux "$soname"; then continue; fi
				[ -e "$stage/$soname" ] && continue
				cp -L "$path" "$stage/$soname"
				echo "   bundled $soname <- $path"
				changed=1
			done < "$work/deps"
		done
	done
}

bundle_darwin() {
	changed=1
	while [ "$changed" = 1 ]; do
		changed=0
		for f in "$stage"/*; do
			otool -L "$f" | tail -n +2 > "$work/deps"
			while read -r dep rest; do
				case "$dep" in /usr/lib/*|/System/*|@loader_path/*) continue ;; esac
				name=${dep##*/}
				if [ ! -e "$stage/$name" ]; then
					src_lib=
					for cand in "$dep" "./$dep" "./lib/$name" "$prefix/lib/$name"; do
						if [ -f "$cand" ]; then src_lib=$cand; break; fi
					done
					[ -n "$src_lib" ] || die "cannot resolve $dep needed by $f"
					cp -L "$src_lib" "$stage/$name"
					chmod u+w "$stage/$name"
					echo "   bundled $name <- $src_lib"
					changed=1
				fi
				install_name_tool -change "$dep" "@loader_path/$name" "$f" || true
			done < "$work/deps"
		done
	done
	for f in "$stage"/*; do
		case "$f" in *.dylib) install_name_tool -id "@loader_path/${f##*/}" "$f" ;; esac
		codesign --force --sign - "$f" >/dev/null 2>&1 || true
	done
}

bundle_win32() {
	changed=1
	while [ "$changed" = 1 ]; do
		changed=0
		for f in "$stage"/*; do
			# (a "cmd && echo" as the last command of a pipeline loop exits 1 under set -e)
			objdump -p "$f" > "$work/pe"
			: > "$work/deps"
			cr=$(printf '\r')
			while read -r a b c; do
				if [ "$a $b" = "DLL Name:" ]; then echo "${c%"$cr"}" >> "$work/deps"; fi
			done < "$work/pe"
			while read -r dll; do
				[ -e "$stage/$dll" ] && continue
				found=
				for d in ./lib "$prefix/bin" "$prefix/lib" /mingw64/bin; do
					if [ -f "$d/$dll" ]; then found=$d/$dll; break; fi
				done
				if [ -z "$found" ]; then
					# Not ours: it must be a Windows system DLL, or the addon would fail to load
					# on a clean machine (the dependency was never installed in this job).
					case "$dll" in
						[Nn][Oo][Dd][Ee].[Ee][Xx][Ee]|api-ms-win-*|ext-ms-win-*) continue ;;
					esac
					sysdir=$(cygpath -S 2>/dev/null || echo /c/Windows/System32)
					[ -f "$sysdir/$dll" ] && continue
					die "$dll (needed by ${f##*/}) was not found: install it in this job (deps_winget) so it can be bundled"
				fi
				cp -L "$found" "$stage/$dll"
				echo "   bundled $dll <- $found"
				changed=1
			done < "$work/deps"
		done
	done
}

case "$os" in
	linux) bundle_linux ;;
	darwin) bundle_darwin ;;
	win32) bundle_win32 ;;
esac

# ---- self-test: load it with the build's library paths hidden ---------------------------------
if command -v node >/dev/null 2>&1; then
	addon=$out
	if [ "$os" = win32 ] && command -v cygpath >/dev/null 2>&1; then addon=$(cygpath -m "$out"); fi
	env -u LD_LIBRARY_PATH -u DYLD_LIBRARY_PATH node -e '
		const m = { exports: {} };
		process.dlopen(m, process.argv[1]);
		const names = Object.getOwnPropertyNames(m.exports);
		if (names.length === 0) { console.error("addon loaded but exports nothing"); process.exit(1); }
		console.log("   self-test ok: " + names.join(", "));
	' "$addon" || die "self-test failed: the addon does not load"
else
	echo "   node not found: self-test skipped (the npm-verify job loads it on this platform)"
fi

# ---- package ---------------------------------------------------------------------------------
mkdir -p "$work/pack/prebuilds/$key"
cp -R "$stage"/. "$work/pack/prebuilds/$key/"
tarball=$outdir/node-prebuild-$key.tar.gz
tar -czf "$tarball" -C "$work/pack" prebuilds
echo "== wrote $tarball"
tar -tzf "$tarball"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
	gh_out=$GITHUB_OUTPUT
	if [ "$os" = win32 ] && command -v cygpath >/dev/null 2>&1; then gh_out=$(cygpath -u "$GITHUB_OUTPUT"); fi
	echo "key=$key" >> "$gh_out"
fi
