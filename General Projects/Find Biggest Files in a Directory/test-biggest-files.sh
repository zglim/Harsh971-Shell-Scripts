#!/bin/bash

# Regression tests for biggest-files.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$SCRIPT_DIR/biggest-files.sh"
PASS=0
FAIL=0
TMPDIR_BASE="$(mktemp -d)"

cleanup() {
    rm -rf "$TMPDIR_BASE"
    rm -f ./filesize.txt
}
trap cleanup EXIT

assert_exit() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" -eq "$actual" ]; then
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $desc (expected exit $expected, got $actual)"
        FAIL=$((FAIL + 1))
    fi
}

# --- Test 1: Normal directory ---
test_dir="$TMPDIR_BASE/normal"
mkdir -p "$test_dir"
for i in 1 2 3 4 5 6; do
    dd if=/dev/zero of="$test_dir/file$i" bs=1024 count=$((i * 10)) 2>/dev/null
done

output=$(bash "$SCRIPT" "$test_dir" 2>&1)
assert_exit "Normal directory exits 0" 0 $?

lines=$(wc -l < ./filesize.txt | tr -d ' ')
if [ "$lines" -eq 5 ]; then
    echo "PASS: Output file has exactly 5 lines"
    PASS=$((PASS + 1))
else
    echo "FAIL: Output file has $lines lines, expected 5"
    FAIL=$((FAIL + 1))
fi
rm -f ./filesize.txt

# --- Test 2: No argument ---
output=$(bash "$SCRIPT" 2>&1)
assert_exit "No argument exits non-zero" 1 $?

# --- Test 3: Non-existent directory ---
output=$(bash "$SCRIPT" "/no/such/path/xyz" 2>&1)
assert_exit "Non-existent path exits non-zero" 1 $?
if echo "$output" | grep -qi "does not exist"; then
    echo "PASS: Non-existent path shows error message"
    PASS=$((PASS + 1))
else
    echo "FAIL: Non-existent path missing error message"
    FAIL=$((FAIL + 1))
fi

# --- Test 4: File instead of directory ---
touch "$TMPDIR_BASE/afile.txt"
output=$(bash "$SCRIPT" "$TMPDIR_BASE/afile.txt" 2>&1)
assert_exit "File argument exits non-zero" 1 $?
if echo "$output" | grep -qi "not a directory"; then
    echo "PASS: File argument shows error message"
    PASS=$((PASS + 1))
else
    echo "FAIL: File argument missing error message"
    FAIL=$((FAIL + 1))
fi

# --- Test 5: Directory with spaces ---
space_dir="$TMPDIR_BASE/dir with spaces"
mkdir -p "$space_dir"
dd if=/dev/zero of="$space_dir/some file.bin" bs=1024 count=50 2>/dev/null

output=$(bash "$SCRIPT" "$space_dir" 2>&1)
assert_exit "Directory with spaces exits 0" 0 $?
if [ -f ./filesize.txt ] && [ -s ./filesize.txt ]; then
    echo "PASS: Directory with spaces produces output"
    PASS=$((PASS + 1))
else
    echo "FAIL: Directory with spaces produced no output"
    FAIL=$((FAIL + 1))
fi
rm -f ./filesize.txt

# --- Summary ---
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
