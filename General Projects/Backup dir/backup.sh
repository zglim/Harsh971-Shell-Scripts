#!/bin/bash

# backup.sh - Configurable directory backup tool
# Usage:
#   backup.sh -s <source_dir> -d <destination_dir> [-p <prefix>] [-l] [-k <keep_n>]

set -euo pipefail

# Defaults
PREFIX="backup"
LIST_ONLY=false
KEEP=0

usage() {
    cat <<EOF
Usage: $0 -s <source_dir> -d <destination_dir> [-p <prefix>] [-l] [-k <n>]

Options:
  -s  Source directory to back up (required)
  -d  Destination directory for backups (required)
  -p  Backup filename prefix (default: backup)
  -l  List existing backups in destination directory and exit
  -k  Keep only the most recent N backups (0 = keep all, default)
  -h  Show this help message
EOF
}

list_backups() {
    local dest="$1" prefix="$2"
    if [ ! -d "$dest" ]; then
        echo "Destination directory does not exist: $dest"
        return 1
    fi
    local files
    files=$(find "$dest" -maxdepth 1 -name "${prefix}_*.tar.gz" -type f | sort -r)
    if [ -z "$files" ]; then
        echo "No backups found with prefix '${prefix}' in $dest"
    else
        echo "Existing backups in $dest:"
        echo "$files" | while read -r f; do
            echo "  $(basename "$f")  ($(du -h "$f" | cut -f1))"
        done
    fi
}

cleanup_old_backups() {
    local dest="$1" prefix="$2" keep="$3"
    local files
    files=$(find "$dest" -maxdepth 1 -name "${prefix}_*.tar.gz" -type f | sort -r)
    local count
    count=$(echo "$files" | grep -c . || true)
    if [ "$count" -gt "$keep" ]; then
        echo "$files" | tail -n +"$((keep + 1))" | while read -r f; do
            echo "Removing old backup: $(basename "$f")"
            rm -f "$f"
        done
    fi
}

# Parse arguments
SOURCE_DIR=""
DEST_DIR=""
while getopts "s:d:p:k:lh" opt; do
    case $opt in
        s) SOURCE_DIR="$OPTARG" ;;
        d) DEST_DIR="$OPTARG" ;;
        p) PREFIX="$OPTARG" ;;
        k) KEEP="$OPTARG" ;;
        l) LIST_ONLY=true ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

# Validate required params
if [ -z "$SOURCE_DIR" ] || [ -z "$DEST_DIR" ]; then
    echo "Error: -s <source_dir> and -d <destination_dir> are required." >&2
    usage >&2
    exit 1
fi

# List mode
if [ "$LIST_ONLY" = true ]; then
    list_backups "$DEST_DIR" "$PREFIX"
    exit $?
fi

# Validate source directory
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory does not exist: $SOURCE_DIR" >&2
    exit 1
fi

# Create destination directory if needed
if ! mkdir -p "$DEST_DIR" 2>/dev/null; then
    echo "Error: Cannot create destination directory: $DEST_DIR" >&2
    exit 1
fi

# Build backup filename
timestamp=$(date +"%Y%m%d_%H%M%S")
backup_filename="${PREFIX}_${timestamp}.tar.gz"
backup_path="${DEST_DIR}/${backup_filename}"

# Perform the backup
if tar -czf "$backup_path" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"; then
    echo "Backup successful!"
    echo "  File: $backup_path"
    echo "  Size: $(du -h "$backup_path" | cut -f1)"

    # Cleanup old backups if requested
    if [ "$KEEP" -gt 0 ]; then
        cleanup_old_backups "$DEST_DIR" "$PREFIX" "$KEEP"
    fi
else
    echo "Error: Backup failed!" >&2
    rm -f "$backup_path"
    exit 1
fi
