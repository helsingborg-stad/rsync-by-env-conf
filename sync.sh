#!/bin/bash

# Default values
CONFIG_FILE=""
DRY_RUN_MODE=0
EXCLUDE_FILE=""
INCLUDE_FILE=""
CHANGED_FILES=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --config=*) CONFIG_FILE="${1#--config=}";;
        --dry-run) DRY_RUN_MODE=1;;
        *) echo "Unknown parameter: $1"; exit 1;;
    esac
    shift
done

# Ensure config file is provided
if [ -z "$CONFIG_FILE" ]; then
    echo "Usage: $0 --config=config.env [--dry-run]"
    exit 1
fi

# Validate config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file '$CONFIG_FILE' not found."
    exit 1
fi

# Generate filenames based on the config name
EXCLUDE_FILE="${CONFIG_FILE}.exclude.txt"
INCLUDE_FILE="${CONFIG_FILE}.include.txt"
POST_SYNC_SCRIPT="${CONFIG_FILE}.post-run.sh"

# Validate optional exclude and include files
[ -f "$EXCLUDE_FILE" ] || EXCLUDE_FILE=""
[ -f "$INCLUDE_FILE" ] || INCLUDE_FILE=""

# Load environment variables
source "$CONFIG_FILE"

# Validate required variables
if [ -z "$SSH_DEST" ] || [ -z "$REMOTE_FOLDER" ] || [ -z "$LOCAL_DEST" ]; then
    echo "Error: Missing required configuration variables."
    exit 1
fi

# Default SSH port to 22 if not provided
SSH_PORT="${SSH_PORT:-22}"

# Full remote source path
REMOTE_SRC="$SSH_DEST:$REMOTE_FOLDER"

# Rsync options
RSYNC_OPTIONS="-avz --delete --progress --out-format='%n'"

# Add exclusion and inclusion options if files exist
[ -n "$EXCLUDE_FILE" ] && RSYNC_OPTIONS="$RSYNC_OPTIONS --exclude-from=$EXCLUDE_FILE"
[ -n "$INCLUDE_FILE" ] && RSYNC_OPTIONS="$RSYNC_OPTIONS --include-from=$INCLUDE_FILE"

# Enable dry-run if flag is set
if [ "$DRY_RUN_MODE" -eq 1 ]; then
    RSYNC_OPTIONS="$RSYNC_OPTIONS --dry-run"
    echo "Running in dry-run mode (no files will be modified)."
fi

# Display sync summary
echo "Starting sync..."
echo "Syncing from: $REMOTE_SRC"
echo "Syncing to:   $LOCAL_DEST"
echo "Using SSH port: $SSH_PORT"

# Run rsync and capture changed files in a variable
CHANGED_FILES=$(rsync $RSYNC_OPTIONS -e "ssh -p $SSH_PORT" "$REMOTE_SRC" "$LOCAL_DEST")

# Check if any files were changed
if [ -n "$CHANGED_FILES" ]; then
    echo "Files changed:"
    echo "$CHANGED_FILES"

    # Check if the post-sync script exists and skip if in dry-run mode
    if [ -f "$POST_SYNC_SCRIPT" ] && [ "$DRY_RUN_MODE" -eq 0 ]; then
        echo "Executing post-sync script: $POST_SYNC_SCRIPT"
        chmod +x "$POST_SYNC_SCRIPT"  # Ensure it's executable
        bash "$POST_SYNC_SCRIPT"
    else
        if [ "$DRY_RUN_MODE" -eq 1 ]; then
            echo "Skipping post-sync script in dry-run mode."
        else
            echo "No post-sync script found."
        fi
    fi
else
    echo "No changes detected. Skipping post-sync script."
fi

echo "Sync completed successfully."