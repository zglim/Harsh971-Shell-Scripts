#!/bin/bash

# Simple interactive calculator with input validation.

validate_integer() {
    local value="$1"
    local label="$2"
    if [ -z "$value" ]; then
        echo "Error: ${label} cannot be empty." >&2
        return 1
    fi
    if ! [[ "$value" =~ ^-?[0-9]+$ ]]; then
        echo "Error: ${label} '${value}' is not a valid integer." >&2
        return 1
    fi
    return 0
}

echo "Enter First number : "
read num1

echo "Enter Second number : "
read num2

echo "Enter Operation (+, -, *, /) : "
read op

# Validate inputs
validate_integer "$num1" "First number" || exit 1
validate_integer "$num2" "Second number" || exit 1

case "$op" in
    +) result=$((num1 + num2)) ;;
    -) result=$((num1 - num2)) ;;
    \*) result=$((num1 * num2)) ;;
    /)
        if [ "$num2" -eq 0 ]; then
            echo "Error: Division by zero is not allowed." >&2
            exit 1
        fi
        result=$((num1 / num2))
        ;;
    *)
        echo "Error: Unsupported operator '${op}'. Use +, -, *, or /." >&2
        exit 1
        ;;
esac

echo "The result is : $result"
