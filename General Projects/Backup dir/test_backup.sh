#!/bin/bash

# Regression tests for backup.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SCRIPT="$SCRIPT_DIR/backup.sh"
TEST_DIR=$(mktemp -d)
PASS=0
FAIL=0

cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $desc (expected=$expected, actual=$actual)"
        FAIL=$((FAIL + 1))
    fi
}

assert_contains() {
    local desc="$1" pattern="$2" output="$3"
    if echo "$output" | grep -q "$pattern"; then
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $desc (pattern='$pattern' not found in output)"
        FAIL=$((FAIL + 1))
    fi
}

# Setup: create a source directory with test content
SRC="$TEST_DIR/source"
DEST="$TEST_DIR/dest"
mkdir -p "$SRC"
echo "test content" > "$SRC/file1.txt"
echo "more content" > "$SRC/file2.txt"

# ---- Test 1: Normal backup (default prefix) ----
output=$(bash "$BACKUP_SCRIPT" -s "$SRC" -d "$DEST" 2>&1)
rc=$?
assert_eq "T1: normal backup exits 0" "0" "$rc"
assert_contains "T1: output says successful" "Backup successful" "$output"
assert_contains "T1: output shows destination path" "$DEST" "$output"
# Check that a tar.gz file was actually created
count=$(find "$DEST" -maxdepth 1 -name "backup_*.tar.gz" -type f | wc -l | tr -d ' ')
assert_eq "T1: tar.gz file created" "1" "$count"

# ---- Test 2: Custom source/destination paths ----
SRC2="$TEST_DIR/src2"
DEST2="$TEST_DIR/dst2"
mkdir -p "$SRC2"
echo "hello" > "$SRC2/data.txt"
output=$(bash "$BACKUP_SCRIPT" -s "$SRC2" -d "$DEST2" 2>&1)
rc=$?
assert_eq "T2: custom paths exits 0" "0" "$rc"
assert_contains "T2: output shows custom source" "$SRC2" "$output"
count=$(find "$DEST2" -maxdepth 1 -name "backup_*.tar.gz" -type f | wc -l | tr -d ' ')
assert_eq "T2: archive created in custom dest" "1" "$count"

# ---- Test 3: Invalid source directory ----
output=$(bash "$BACKUP_SCRIPT" -s "/nonexistent/path/xyz" -d "$DEST" 2>&1)
rc=$?
assert_eq "T3: invalid source exits non-zero" "1" "$rc"
assert_contains "T3: error mentions source" "Source directory does not exist" "$output"

# ---- Test 4: Missing parameters ----
output=$(bash "$BACKUP_SCRIPT" 2>&1)
rc=$?
assert_eq "T4: no params exits non-zero" "1" "$rc"

output=$(bash "$BACKUP_SCRIPT" -s "$SRC" 2>&1)
rc=$?
assert_eq "T4b: missing dest exits non-zero" "1" "$rc"
assert_contains "T4b: error mentions dest required" "Destination directory (-d) is required" "$output"

# ---- Test 5: Custom prefix ----
DEST3="$TEST_DIR/dst3"
output=$(bash "$BACKUP_SCRIPT" -s "$SRC" -d "$DEST3" -p "myapp" 2>&1)
rc=$?
assert_eq "T5: custom prefix exits 0" "0" "$rc"
count=$(find "$DEST3" -maxdepth 1 -name "myapp_*.tar.gz" -type f | wc -l | tr -d ' ')
assert_eq "T5: archive uses custom prefix" "1" "$count"

# ---- Test 6: List backups ----
output=$(bash "$BACKUP_SCRIPT" -d "$DEST" -l 2>&1)
rc=$?
assert_eq "T6: list mode exits 0" "0" "$rc"
assert_contains "T6: output shows 'Existing backups'" "Existing backups" "$output"
assert_contains "T6: lists the backup file" "backup_" "$output"

# ---- Test 7: List backups on nonexistent dir ----
output=$(bash "$BACKUP_SCRIPT" -d "/nonexistent/dir" -l 2>&1)
rc=$?
assert_eq "T7: list nonexistent dir exits non-zero" "1" "$rc"
assert_contains "T7: error about destination" "Destination directory does not exist" "$output"

# ---- Test 8: Verify archive contents ----
archive=$(find "$DEST" -maxdepth 1 -name "backup_*.tar.gz" -type f | head -1)
if [ -n "$archive" ]; then
    contents=$(tar -tzf "$archive" 2>&1)
    assert_contains "T8: archive contains source files" "file1.txt" "$contents"
else
    echo "FAIL: T8: no archive found to verify"
    FAIL=$((FAIL + 1))
fi

# ---- Summary ----
echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
