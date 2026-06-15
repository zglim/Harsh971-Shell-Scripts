#!/bin/bash

# Regression tests for calculator.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CALC="$SCRIPT_DIR/calculator.sh"
PASS=0
FAIL=0

run_test() {
    local desc="$1"
    local input="$2"
    local expect_exit="$3"
    local expect_pattern="$4"

    output=$(echo "$input" | bash "$CALC" 2>&1)
    actual_exit=$?

    if [ "$actual_exit" -ne "$expect_exit" ]; then
        echo "FAIL: $desc — expected exit $expect_exit, got $actual_exit"
        FAIL=$((FAIL + 1))
        return
    fi

    if [ -n "$expect_pattern" ] && ! echo "$output" | grep -qF "$expect_pattern"; then
        echo "FAIL: $desc — output missing '$expect_pattern'"
        echo "      got: $output"
        FAIL=$((FAIL + 1))
        return
    fi

    echo "PASS: $desc"
    PASS=$((PASS + 1))
}

# --- Normal operations ---
run_test "addition"        "10
5
+"  0 "The result is : 15"
run_test "subtraction"     "10
5
-"  0 "The result is : 5"
run_test "multiplication"  "10
5
*"  0 "The result is : 50"
run_test "division"        "10
5
/"  0 "The result is : 2"
run_test "negative numbers" "-3
7
+"  0 "The result is : 4"

# --- Invalid number inputs ---
run_test "first num empty"     "
5
+"  1 "Error:"
run_test "second num empty"    "5

+"  1 "Error:"
run_test "first num letters"   "abc
5
+"  1 "Error:"
run_test "second num float"    "5
3.5
+"  1 "Error:"

# --- Unsupported operator ---
run_test "bad operator %"      "5
3
%"  1 "Error:"
run_test "operator empty"      "5
3
"   1 "Error:"

# --- Division by zero ---
run_test "divide by zero"      "10
0
/"  1 "Error:"

echo ""
echo "Results: $PASS passed, $FAIL failed out of $((PASS + FAIL)) tests"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
