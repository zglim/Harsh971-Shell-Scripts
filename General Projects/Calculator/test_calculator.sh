#!/bin/bash
# Regression tests for calculator.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CALC="$SCRIPT_DIR/calculator.sh"

passed=0
failed=0

run_test() {
    local desc="$1"
    local input="$2"
    local expect_exit="$3"
    local expect_output="$4"  # substring match

    local output
    local actual_exit

    output=$(printf '%s\n' "$input" | bash "$CALC" 2>&1)
    actual_exit=$?

    local ok=true

    if [ "$actual_exit" -ne "$expect_exit" ]; then
        ok=false
    fi

    if [ -n "$expect_output" ]; then
        if [[ "$output" != *"$expect_output"* ]]; then
            ok=false
        fi
    fi

    if $ok; then
        echo "PASS: $desc"
        passed=$((passed + 1))
    else
        echo "FAIL: $desc"
        echo "  expected exit=$expect_exit, got exit=$actual_exit"
        echo "  expected output to contain: '$expect_output'"
        echo "  actual output: '$output'"
        failed=$((failed + 1))
    fi
}

# --- Normal arithmetic ---
run_test "addition 3+5=8"          $'3\n5\n+' 0 "The result is : 8"
run_test "subtraction 10-4=6"     $'10\n4\n-' 0 "The result is : 6"
run_test "multiplication 3*4=12"  $'3\n4\n*' 0 "The result is : 12"
run_test "division 20/4=5"        $'20\n4\n/' 0 "The result is : 5"
run_test "negative result 2-7=-5" $'2\n7\n-' 0 "The result is : -5"
run_test "division 7/2=3 (int)"   $'7\n2\n/' 0 "The result is : 3"

# --- Division by zero ---
run_test "division by zero"       $'10\n0\n/' 1 "division by zero"

# --- Invalid number input ---
run_test "empty first number"     $'\n5\n+' 1 "is empty"
run_test "empty second number"    $'3\n\n+' 1 "is empty"
run_test "non-numeric first num"  $'abc\n5\n+' 1 "not a valid integer"
run_test "non-numeric second num" $'3\nxyz\n+' 1 "not a valid integer"
run_test "float input rejected"   $'3.5\n2\n+' 1 "not a valid integer"

# --- Invalid operator ---
run_test "unsupported operator %" $'3\n5\n%' 1 "not a supported operator"
run_test "empty operator"         $'3\n5\n' 1 "is empty"
run_test "letter as operator"     $'3\n5\nx' 1 "not a supported operator"

# --- Summary ---
echo ""
echo "==============================="
echo "Passed: $passed  Failed: $failed"
echo "==============================="

[ "$failed" -eq 0 ]
