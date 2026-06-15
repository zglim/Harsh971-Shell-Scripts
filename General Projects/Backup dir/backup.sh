#!/bin/bash

# Configurable backup tool
# Usage: backup.sh -s <source_dir> -d <destination_dir> [-p <prefix>] [-l]

usage() {
    echo "Usage: $0 -s <source_dir> -d <destination_dir> [-p <prefix>] [-l]"
    echo "  -s  Source directory to back up (required)"
    echo "  -d  Destination directory for backup files (required)"
    echo "  -p  Custom prefix for backup filename (default: backup)"
    echo "  -l  List existing backups in destination directory and exit"
    exit 1
}

# Defaults
prefix="backup"
list_mode=false
source_dir=""
destination_dir=""

# Parse command-line arguments
while getopts "s:d:p:lh" opt; do
    case "$opt" in
        s) source_dir="$OPTARG" ;;
        d) destination_dir="$OPTARG" ;;
        p) prefix="$OPTARG" ;;
        l) list_mode=true ;;
        h) usage ;;
        *) usage ;;
    esac
done

# --- Validate parameters ---

# List mode only needs destination_dir
if $list_mode; then
    if [ -z "$destination_dir" ]; then
        echo "Error: Destination directory (-d) is required for listing backups."
        exit 1
    fi
    if [ ! -d "$destination_dir" ]; then
        echo "Error: Destination directory does not exist: $destination_dir"
        exit 1
    fi
    echo "Existing backups in $destination_dir:"
    found=$(find "$destination_dir" -maxdepth 1 -name "*.tar.gz" -type f | sort)
    if [ -z "$found" ]; then
        echo "  (none)"
    else
        echo "$found" | while read -r f; do
            echo "  $(basename "$f")"
        done
    fi
    exit 0
fi

# For backup mode, both source and destination are required
if [ -z "$source_dir" ]; then
    echo "Error: Source directory (-s) is required."
    exit 1
fi

if [ -z "$destination_dir" ]; then
    echo "Error: Destination directory (-d) is required."
    exit 1
fi

# Validate source directory exists
if [ ! -d "$source_dir" ]; then
    echo "Error: Source directory does not exist: $source_dir"
    exit 1
fi

# Create the destination directory if it doesn't exist
if ! mkdir -p "$destination_dir" 2>/dev/null; then
    echo "Error: Cannot create destination directory: $destination_dir"
    exit 1
fi

# --- Execute backup ---

# Create a timestamp for the backup file
timestamp=$(date +"%Y%m%d_%H%M%S")

# Define the backup filename using the prefix
backup_filename="${prefix}_${timestamp}.tar.gz"
backup_path="${destination_dir}/${backup_filename}"

# Perform the backup
tar -czf "$backup_path" -C "$(dirname "$source_dir")" "$(basename "$source_dir")"

# --- Output result ---
if [ $? -eq 0 ]; then
    echo "Backup successful!"
    echo "  Source:      $source_dir"
    echo "  Destination: $backup_path"
else
    echo "Backup failed!"
    exit 1
fi
