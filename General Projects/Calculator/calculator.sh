#!/bin/bash

# --- Validation helpers ---

validate_integer() {
    local value="$1"
    local label="$2"
    if [ -z "$value" ]; then
        echo "Error: $label is empty. Please enter an integer." >&2
        return 1
    fi
    if ! [[ "$value" =~ ^-?[0-9]+$ ]]; then
        echo "Error: '$value' is not a valid integer for $label." >&2
        return 1
    fi
    return 0
}

validate_operator() {
    local op="$1"
    if [ -z "$op" ]; then
        echo "Error: operator is empty. Please use one of: +, -, *, /" >&2
        return 1
    fi
    case "$op" in
        +|-|\*|/) return 0 ;;
        *)
            echo "Error: '$op' is not a supported operator. Please use one of: +, -, *, /" >&2
            return 1
            ;;
    esac
}

# --- Main flow ---

echo "Enter First number : "
read num1
validate_integer "$num1" "first number" || exit 1

echo "Enter Second number : "
read num2
validate_integer "$num2" "second number" || exit 1

echo "Enter Operation (+, -, *, /) : "
read op
validate_operator "$op" || exit 1

case "$op" in
    +) result=$((num1 + num2)) ;;
    -) result=$((num1 - num2)) ;;
    \*) result=$((num1 * num2)) ;;
    /)
        if [ "$num2" -eq 0 ]; then
            echo "Error: division by zero is not allowed." >&2
            exit 1
        fi
        result=$((num1 / num2))
        ;;
esac

echo "The result is : $result"
