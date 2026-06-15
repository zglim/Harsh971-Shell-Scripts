#!/bin/bash

# Find the 5 biggest files/entries in a given directory.

# --- Argument validation ---
if [ $# -lt 1 ]; then
    echo "Error: No directory specified." >&2
    echo "Usage: $0 <directory>" >&2
    exit 1
fi

target_dir="$1"

if [ ! -e "$target_dir" ]; then
    echo "Error: '$target_dir' does not exist." >&2
    exit 1
fi

if [ ! -d "$target_dir" ]; then
    echo "Error: '$target_dir' is not a directory." >&2
    exit 1
fi

# --- Output file: write to a temp file next to the script ---
script_dir="$(cd "$(dirname "$0")" && pwd)"
output_file="${script_dir}/filesize.txt"

echo "First 5 biggest entries in: $target_dir"

# --- Core pipeline: find biggest 5 entries ---
du -ah "$target_dir" 2>/dev/null | sort -hr | head -n 5 > "$output_file"

echo "Results saved to: $output_file"
echo ""
cat "$output_file"
