#!/bin/sh

test ! -z "$RLDD_SO" || RLDD_SO="so"
test ! -z "$RLDD_PATH" || RLDD_PATH=/usr/local/lib:/usr/lib:.
test ! -z "$RLDD" || RLDD=ldd

mkdir rldd 2>/dev/null || true

resolve_dll() {
  for dir in `echo $RLDD_PATH | tr ':' ' '`; do
    if test -f $dir/$1; then
      echo $dir/$1
      return 0
    fi
  done

  echo "not found"
}

recurse() {
  target="$1"
  test -f "$target" || return
  $RLDD "$target" 2>/dev/null | while read -r dll arrow path more; do
    [ -z "$path" ] && continue
    test ! -f rldd/$dll || continue
    if test "$path" = "not"; then
      path="`resolve_dll $dll`"
      more=
    fi
    echo $dll $arrow $path $more
    recurse $path
    touch rldd/$dll
  done
}

recurse "$1"
rm -rf rldd || true
