#!/usr/bin/env bash
# release-notes.sh - Extract release notes from CHANGELOG.md for a given tag
#
# Usage:
#   release-notes.sh <changelog_path> <target_tag> [prev_tag]
#
# Arguments:
#   changelog_path  Path to CHANGELOG.md
#   target_tag      Tag/version to extract (e.g. 1.3.1 or v1.3.1)
#   prev_tag        (Optional) Previous released tag (e.g. 1.0.0 or v1.0.0).
#                   If specified, notes for intermediate versions > prev_tag are
#                   included, and extraction stops before the first version <= prev_tag.
#                   Special value '--single' or '--next': stop at the very next ## heading.
#                   If omitted or empty: extracts to the end of the changelog.

set -euo pipefail

usage() {
    echo "Usage: $0 <changelog_path> <target_tag> [prev_tag]" >&2
    exit 1
}

[ $# -lt 2 ] && usage

CHANGELOG="$1"
TARGET_RAW="$2"
PREV_RAW="${3:-}"

if [ ! -f "$CHANGELOG" ]; then
    echo "Error: changelog file not found: $CHANGELOG" >&2
    exit 1
fi

# Normalize tags: strip leading 'v' or 'V'
TARGET="${TARGET_RAW#v}"
TARGET="${TARGET#V}"

PREV=""
STOP_AT_NEXT=0
if [ "$PREV_RAW" = "--single" ] || [ "$PREV_RAW" = "--next" ]; then
    STOP_AT_NEXT=1
elif [ -n "$PREV_RAW" ]; then
    PREV="${PREV_RAW#v}"
    PREV="${PREV#V}"
fi

# Helper: parse version string from a markdown level-2 heading line
# e.g.:
#   "## [1.3.1]"              -> "1.3.1"
#   "## 1.3.1"                -> "1.3.1"
#   "## [v1.4.1] - 2026-09-27"-> "1.4.1"
#   "## v1.4.1 - 2026-09-27"  -> "1.4.1"
#   "## [1.0.0] - 2026-05-02" -> "1.0.0"
#   "## 1.0.0 (libauren)"     -> "1.0.0"
#   "## [0.1.6] — 2026-05-12" -> "0.1.6"
get_heading_version() {
    local hdr="$1"
    local ver=""
    local re_bracket="^##[[:space:]]+\[[vV]?([^]]+)\]"
    local re_nobracket="^##[[:space:]]+[vV]?([^[:space:]()]+)"

    if [[ "$hdr" =~ $re_bracket ]]; then
        ver="${BASH_REMATCH[1]}"
    elif [[ "$hdr" =~ $re_nobracket ]]; then
        ver="${BASH_REMATCH[1]}"
    fi

    # Strip any leading 'v' or 'V'
    ver="${ver#v}"
    ver="${ver#V}"
    echo "$ver"
}

# Helper: returns 0 if v1 <= v2 according to version sorting
ver_le() {
    local v1="$1"
    local v2="$2"
    [ "$v1" = "$v2" ] && return 0
    [ "$(printf '%s\n%s\n' "$v1" "$v2" | sort -V | head -n1)" = "$v1" ]
}

capturing=0
found_target=0
buffer=""

while IFS= read -r line || [ -n "$line" ]; do
    # Only inspect level-2 markdown headings ("## ..."), not "### ..."
    if [[ "$line" =~ ^##[[:space:]] ]]; then
        ver=$(get_heading_version "$line")

        if [ $capturing -eq 0 ]; then
            # Check literal version equality
            if [ "$ver" = "$TARGET" ]; then
                capturing=1
                found_target=1
                # Output MUST include the target heading line as its first line
                buffer+="$line"$'\n'
                continue
            fi
        else
            # We are already capturing. Should we stop?
            if [ $STOP_AT_NEXT -eq 1 ]; then
                break
            fi

            if [ -n "$PREV" ]; then
                if [ -n "$ver" ] && ver_le "$ver" "$PREV"; then
                    # Reached previous release or older; stop!
                    break
                fi
            fi

            # Continuing across an intermediate unreleased version
            buffer+="$line"$'\n'
            continue
        fi
    fi

    if [ $capturing -eq 1 ]; then
        buffer+="$line"$'\n'
    fi
done < "$CHANGELOG"

if [ $found_target -eq 0 ]; then
    exit 1
fi

# Print accumulated buffer, trimming excessive trailing blank lines but preserving a single trailing newline
printf '%s' "$buffer" | awk '
    /^[[:space:]]*$/ { blank++; next }
    {
        while (blank > 0) { print ""; blank-- }
        print
    }
'
