#!/bin/bash
# Regression tests for biggest-files.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIGGEST_FILES="$SCRIPT_DIR/biggest-files.sh"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }

echo "=== biggest-files.sh regression tests ==="

# ------------------------------------------------------------------
# Test 1: Normal directory input exits 0 and produces output file
# ------------------------------------------------------------------
echo ""
echo "Test 1: Normal directory input"
out=$(bash "$BIGGEST_FILES" "$SCRIPT_DIR" 2>&1)
rc=$?
if [ $rc -eq 0 ]; then
    pass "exit code is 0"
else
    fail "exit code expected 0, got $rc"
fi

output_file="$SCRIPT_DIR/filesize.txt"
if [ -f "$output_file" ]; then
    pass "output file filesize.txt exists"
else
    fail "output file filesize.txt not found"
fi

line_count=$(wc -l < "$output_file" | tr -d ' ')
if [ "$line_count" -le 5 ]; then
    pass "output file has at most 5 lines (got $line_count)"
else
    fail "output file has more than 5 lines (got $line_count)"
fi

# ------------------------------------------------------------------
# Test 2: Missing argument exits non-zero with error message
# ------------------------------------------------------------------
echo ""
echo "Test 2: Missing argument"
out=$(bash "$BIGGEST_FILES" 2>&1)
rc=$?
if [ $rc -ne 0 ]; then
    pass "exit code is non-zero ($rc)"
else
    fail "exit code expected non-zero, got 0"
fi
if echo "$out" | grep -qi "error\|usage"; then
    pass "error/usage message shown"
else
    fail "no error/usage message in output"
fi

# ------------------------------------------------------------------
# Test 3: Non-existent directory exits non-zero
# ------------------------------------------------------------------
echo ""
echo "Test 3: Non-existent directory"
out=$(bash "$BIGGEST_FILES" "/no/such/directory/xyz123" 2>&1)
rc=$?
if [ $rc -ne 0 ]; then
    pass "exit code is non-zero ($rc)"
else
    fail "exit code expected non-zero, got 0"
fi
if echo "$out" | grep -qi "not exist\|error"; then
    pass "error message mentions non-existence"
else
    fail "no relevant error message in output"
fi

# ------------------------------------------------------------------
# Test 4: Passing a file instead of directory exits non-zero
# ------------------------------------------------------------------
echo ""
echo "Test 4: File passed instead of directory"
tmp_file=$(mktemp)
out=$(bash "$BIGGEST_FILES" "$tmp_file" 2>&1)
rc=$?
rm -f "$tmp_file"
if [ $rc -ne 0 ]; then
    pass "exit code is non-zero ($rc)"
else
    fail "exit code expected non-zero, got 0"
fi
if echo "$out" | grep -qi "not a directory\|error"; then
    pass "error message mentions not-a-directory"
else
    fail "no relevant error message in output"
fi

# ------------------------------------------------------------------
# Test 5: Directory with spaces in name
# ------------------------------------------------------------------
echo ""
echo "Test 5: Directory with spaces in name"
space_dir=$(mktemp -d -t "biggest files test XXXX")
# Create some files inside
dd if=/dev/zero of="$space_dir/file_a.txt" bs=1024 count=10 2>/dev/null
dd if=/dev/zero of="$space_dir/file_b.txt" bs=1024 count=5  2>/dev/null
dd if=/dev/zero of="$space_dir/file_c.txt" bs=1024 count=1  2>/dev/null
out=$(bash "$BIGGEST_FILES" "$space_dir" 2>&1)
rc=$?
if [ $rc -eq 0 ]; then
    pass "exit code is 0 for spaced directory"
else
    fail "exit code expected 0, got $rc"
fi
if echo "$out" | grep -q "file_a.txt"; then
    pass "output contains expected file from spaced directory"
else
    fail "output missing expected file from spaced directory"
fi
rm -rf "$space_dir"

# ------------------------------------------------------------------
# Test 6: Output file is overwritten (not appended) on each run
# ------------------------------------------------------------------
echo ""
echo "Test 6: Output file is overwritten on repeated runs"
bash "$BIGGEST_FILES" "$SCRIPT_DIR" >/dev/null 2>&1
first_lines=$(wc -l < "$output_file" | tr -d ' ')
bash "$BIGGEST_FILES" "$SCRIPT_DIR" >/dev/null 2>&1
second_lines=$(wc -l < "$output_file" | tr -d ' ')
if [ "$first_lines" -eq "$second_lines" ]; then
    pass "output file line count stable across runs ($first_lines == $second_lines)"
else
    fail "output file grew between runs ($first_lines -> $second_lines)"
fi

# ------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ] && exit 0 || exit 1
