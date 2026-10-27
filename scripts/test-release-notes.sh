#!/usr/bin/env bash
# test-release-notes.sh - Test suite for release-notes.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_NOTES_SH="$SCRIPT_DIR/release-notes.sh"

TMPDIR=$(mktemp -d /tmp/test-relnotes-XXXXXX)
trap 'rm -rf "$TMPDIR"' EXIT

passed=0
failed=0

assert_eq() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $test_name"
        passed=$((passed + 1))
    else
        echo "  FAIL: $test_name"
        echo "    --- Expected ---"
        echo "$expected"
        echo "    --- Actual ---"
        echo "$actual"
        failed=$((failed + 1))
    fi
}

assert_exit_code() {
    local test_name="$1"
    local expected_code="$2"
    local actual_code="$3"
    if [ "$expected_code" -eq "$actual_code" ]; then
        echo "  PASS: $test_name (exit code $expected_code)"
        passed=$((passed + 1))
    else
        echo "  FAIL: $test_name (expected exit code $expected_code, got $actual_code)"
        failed=$((failed + 1))
    fi
}

echo "Running release-notes.sh test suite..."

# Fixture 1: Mixed bracketed and unbracketed headings with dates and comments
cat << 'EOF' > "$TMPDIR/fixture1.md"
# Changelog

All notable changes are documented here.

## 1.3.1

- Bugfix A
- Bugfix B

## 1.3.0

- Feature 1
- Feature 2

## [1.2.0]

- Feature 1.2

## 1.1.0

- Feature 1.1

## [1.0.0] - 2026-05-02

- Initial release

## [0.0.1] - 2025-12-17

- Alpha
EOF

# Test 1: Output line 1 MUST match the target tag heading exactly
out=$(bash "$RELEASE_NOTES_SH" "$TMPDIR/fixture1.md" "1.3.1" "1.0.0")
first_line=$(echo "$out" | head -n1)
assert_eq "Heading inclusion: first line is ## 1.3.1" "## 1.3.1" "$first_line"

# Test 2: Extraction includes 1.3.1 down to 1.1.0 and stops at 1.0.0 (prev-release cutoff)
expected_t2=$(cat << 'EOF'
## 1.3.1

- Bugfix A
- Bugfix B

## 1.3.0

- Feature 1
- Feature 2

## [1.2.0]

- Feature 1.2

## 1.1.0

- Feature 1.1
EOF
)
assert_eq "Range extraction stops before prev tag 1.0.0" "$expected_t2" "$out"

# Test 3: Tag with 'v' prefix in arguments matches unbracketed heading
out_v=$(bash "$RELEASE_NOTES_SH" "$TMPDIR/fixture1.md" "v1.3.1" "v1.0.0")
assert_eq "v-prefix in arguments works seamlessly" "$expected_t2" "$out_v"

# Test 4: Target tag with bracketed heading has first line as ## [1.2.0]
out_120=$(bash "$RELEASE_NOTES_SH" "$TMPDIR/fixture1.md" "1.2.0" "1.1.0")
first_line_120=$(echo "$out_120" | head -n1)
assert_eq "Heading inclusion: first line is ## [1.2.0]" "## [1.2.0]" "$first_line_120"

expected_120=$(cat << 'EOF'
## [1.2.0]

- Feature 1.2
EOF
)
assert_eq "Extraction of 1.2.0 stopping before 1.1.0" "$expected_120" "$out_120"

# Test 5: Empty prev_tag continues to end of changelog
out_end=$(bash "$RELEASE_NOTES_SH" "$TMPDIR/fixture1.md" "1.0.0")
expected_end=$(cat << 'EOF'
## [1.0.0] - 2026-05-02

- Initial release

## [0.0.1] - 2025-12-17

- Alpha
EOF
)
assert_eq "Empty prev_tag continues to end of changelog" "$expected_end" "$out_end"

# Test 6: --single or --next stops at the very next heading
out_single=$(bash "$RELEASE_NOTES_SH" "$TMPDIR/fixture1.md" "1.0.0" "--single")
expected_single=$(cat << 'EOF'
## [1.0.0] - 2026-05-02

- Initial release
EOF
)
assert_eq "--single stops at next heading" "$expected_single" "$out_single"

out_next=$(bash "$RELEASE_NOTES_SH" "$TMPDIR/fixture1.md" "1.3.1" "--next")
expected_next=$(cat << 'EOF'
## 1.3.1

- Bugfix A
- Bugfix B
EOF
)
assert_eq "--next stops at next heading" "$expected_next" "$out_next"

# Fixture 2: Literal dot matching & regex safety
cat << 'EOF' > "$TMPDIR/fixture_dots.md"
# Changelog

## [102.0.0]
- One hundred and two

## [1.2.0]
- One point two

## [1.20.0]
- One point twenty
EOF

# Test 7: Target tag 1.2.0 must NOT match 102.0.0 or 1.20.0
out_dot=$(bash "$RELEASE_NOTES_SH" "$TMPDIR/fixture_dots.md" "1.2.0" "--single")
first_line_dot=$(echo "$out_dot" | head -n1)
assert_eq "Literal dot match: correctly selects ## [1.2.0]" "## [1.2.0]" "$first_line_dot"

# Test 8: Target tag 1.20.0 selects 1.20.0
out_dot20=$(bash "$RELEASE_NOTES_SH" "$TMPDIR/fixture_dots.md" "1.20.0" "--single")
first_line_dot20=$(echo "$out_dot20" | head -n1)
assert_eq "Literal dot match: correctly selects ## [1.20.0]" "## [1.20.0]" "$first_line_dot20"

# Fixture 3: Em-dash and unicode dates in heading
cat << 'EOF' > "$TMPDIR/fixture_unicode.md"
# Changelog

## [0.1.6] — 2026-05-12
- Unicode em-dash date heading

## [0.1.5] - 2026-05-07
- Hyphen date heading
EOF

# Test 9: Unicode em-dash in heading parsed properly
out_uni=$(bash "$RELEASE_NOTES_SH" "$TMPDIR/fixture_unicode.md" "0.1.6" "0.1.5")
expected_uni=$(cat << 'EOF'
## [0.1.6] — 2026-05-12
- Unicode em-dash date heading
EOF
)
assert_eq "Unicode em-dash heading parsed and stopped" "$expected_uni" "$out_uni"

# Test 10: Nonexistent tag exits with code 1 and emits no stdout
code=0
out_missing=$(bash "$RELEASE_NOTES_SH" "$TMPDIR/fixture1.md" "9.9.9" 2>/dev/null) || code=$?
assert_exit_code "Nonexistent tag exits with code 1" 1 "$code"
assert_eq "Nonexistent tag stdout is empty" "" "$out_missing"

# Test 11: Real-world check against libcorm CHANGELOG
if [ -f "/home/quirinpa/site/external/libcorm/CHANGELOG.md" ]; then
    out_corm=$(bash "$RELEASE_NOTES_SH" "/home/quirinpa/site/external/libcorm/CHANGELOG.md" "2.1.0" "2.0.0")
    first_corm=$(echo "$out_corm" | head -n1)
    assert_eq "Real libcorm 2.1.0 line 1 is ## [2.1.0]" "## [2.1.0]" "$first_corm"
    # Ensure 2.0.0 heading is NOT present
    has_200=$(echo "$out_corm" | grep -c '## \[2.0.0\]' || true)
    assert_eq "Real libcorm 2.1.0 does not contain ## [2.0.0]" "0" "$has_200"
fi

echo ""
echo "Test summary: $passed passed, $failed failed."
if [ "$failed" -gt 0 ]; then
    exit 1
fi
