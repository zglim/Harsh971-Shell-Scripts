#!/bin/bash

# test_backup.sh - Regression tests for backup.sh
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SCRIPT="$SCRIPT_DIR/backup.sh"
TEST_DIR=$(mktemp -d)
PASS=0
FAIL=0

cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

pass() { echo "PASS: $1"; ((PASS++)); }
fail() { echo "FAIL: $1"; ((FAIL++)); }

# --- Test 1: Normal backup with explicit -s and -d ---
test_normal_backup() {
    local name="normal backup"
    local src="$TEST_DIR/src1" dst="$TEST_DIR/dst1"
    mkdir -p "$src"
    echo "hello" > "$src/file1.txt"
    echo "world" > "$src/file2.txt"

    output=$(bash "$BACKUP_SCRIPT" -s "$src" -d "$dst" 2>&1)
    rc=$?
    if [ $rc -ne 0 ]; then fail "$name (exit=$rc)"; return; fi

    # Check tar.gz actually created
    local count
    count=$(find "$dst" -maxdepth 1 -name "backup_*.tar.gz" | wc -l | tr -d ' ')
    if [ "$count" -eq 1 ]; then
        pass "$name"
    else
        fail "$name (expected 1 archive, got $count)"
    fi
}

# --- Test 2: Custom prefix ---
test_custom_prefix() {
    local name="custom prefix"
    local src="$TEST_DIR/src2" dst="$TEST_DIR/dst2"
    mkdir -p "$src"
    echo "data" > "$src/data.txt"

    output=$(bash "$BACKUP_SCRIPT" -s "$src" -d "$dst" -p mybackup 2>&1)
    rc=$?
    if [ $rc -ne 0 ]; then fail "$name (exit=$rc)"; return; fi

    local count
    count=$(find "$dst" -maxdepth 1 -name "mybackup_*.tar.gz" | wc -l | tr -d ' ')
    if [ "$count" -eq 1 ]; then
        pass "$name"
    else
        fail "$name (expected 1 mybackup archive, got $count)"
    fi
}

# --- Test 3: Non-existent source directory ---
test_invalid_source() {
    local name="invalid source dir"
    local src="$TEST_DIR/nonexistent_src" dst="$TEST_DIR/dst3"

    output=$(bash "$BACKUP_SCRIPT" -s "$src" -d "$dst" 2>&1)
    rc=$?
    if [ $rc -ne 0 ] && echo "$output" | grep -qi "error"; then
        pass "$name"
    else
        fail "$name (exit=$rc, expected non-zero)"
    fi
}

# --- Test 4: Missing required arguments ---
test_missing_args() {
    local name="missing required args"

    output=$(bash "$BACKUP_SCRIPT" 2>&1)
    rc=$?
    if [ $rc -ne 0 ] && echo "$output" | grep -qi "required"; then
        pass "$name"
    else
        fail "$name (exit=$rc, expected non-zero with 'required' message)"
    fi
}

# --- Test 5: Custom dest path ---
test_custom_dest_path() {
    local name="custom dest path"
    local src="$TEST_DIR/src5" dst="$TEST_DIR/nested/deep/dst5"
    mkdir -p "$src"
    echo "nested" > "$src/nested.txt"

    output=$(bash "$BACKUP_SCRIPT" -s "$src" -d "$dst" 2>&1)
    rc=$?
    if [ $rc -ne 0 ]; then fail "$name (exit=$rc)"; return; fi

    local count
    count=$(find "$dst" -maxdepth 1 -name "backup_*.tar.gz" | wc -l | tr -d ' ')
    if [ "$count" -eq 1 ]; then
        pass "$name"
    else
        fail "$name (expected 1 archive, got $count)"
    fi
}

# --- Test 6: List backups ---
test_list_backups() {
    local name="list backups"
    local src="$TEST_DIR/src6" dst="$TEST_DIR/dst6"
    mkdir -p "$src"
    echo "a" > "$src/a.txt"

    # Create two backups
    bash "$BACKUP_SCRIPT" -s "$src" -d "$dst" -p test > /dev/null 2>&1
    sleep 1
    bash "$BACKUP_SCRIPT" -s "$src" -d "$dst" -p test > /dev/null 2>&1

    output=$(bash "$BACKUP_SCRIPT" -s "$src" -d "$dst" -p test -l 2>&1)
    rc=$?
    local count
    count=$(echo "$output" | grep -c "test_.*\.tar\.gz" || true)
    if [ $rc -eq 0 ] && [ "$count" -eq 2 ]; then
        pass "$name"
    else
        fail "$name (exit=$rc, found $count backups in list)"
    fi
}

# --- Test 7: Keep N backups (cleanup) ---
test_keep_n() {
    local name="keep N backups"
    local src="$TEST_DIR/src7" dst="$TEST_DIR/dst7"
    mkdir -p "$src"
    echo "k" > "$src/k.txt"

    # Create 3 backups
    for i in 1 2 3; do
        bash "$BACKUP_SCRIPT" -s "$src" -d "$dst" -p keep > /dev/null 2>&1
        sleep 1
    done

    # Run again with -k 1 to keep only the newest
    output=$(bash "$BACKUP_SCRIPT" -s "$src" -d "$dst" -p keep -k 1 2>&1)
    rc=$?
    if [ $rc -ne 0 ]; then fail "$name (exit=$rc)"; return; fi

    local count
    count=$(find "$dst" -maxdepth 1 -name "keep_*.tar.gz" | wc -l | tr -d ' ')
    if [ "$count" -eq 1 ]; then
        pass "$name"
    else
        fail "$name (expected 1 archive after cleanup, got $count)"
    fi
}

# Run all tests
echo "Running backup.sh regression tests..."
echo "======================================="
test_normal_backup
test_custom_prefix
test_invalid_source
test_missing_args
test_custom_dest_path
test_list_backups
test_keep_n
echo "======================================="
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
