#!/bin/bash

# Find the 5 biggest files/entries in a given directory.

if [ $# -lt 1 ]; then
    echo "Error: No directory provided." >&2
    echo "Usage: $0 <directory>" >&2
    exit 1
fi

path="$1"

if [ ! -e "$path" ]; then
    echo "Error: '$path' does not exist." >&2
    exit 1
fi

if [ ! -d "$path" ]; then
    echo "Error: '$path' is not a directory." >&2
    exit 1
fi

output_file="./filesize.txt"

echo "Top 5 biggest entries in: $path"

du -ah "$path" | sort -hr | head -n 5 > "$output_file"

cat "$output_file"
