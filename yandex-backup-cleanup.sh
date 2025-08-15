#!/usr/bin/env bash

# rclone-yandex-cleanup
# Automated backup rotation and cleanup tool for Yandex Disk using rclone
# Version: 1.0.0
# Repository: https://github.com/nurkamol/rclone-yandex-cleanup

# Lock file to prevent multiple instances
LOCKFILE="/var/lock/rclone-yandex-cleanup.lock"
LOCKFD=99

# Acquire lock
exec 99>"$LOCKFILE"
if ! flock -n 99; then
    echo "Another instance is already running. Exiting."
    exit 1
fi

# Configuration
REMOTE_NAME="yandex-disk"
REMOTE_PATH="Backups"
LOCAL_BACKUP_PATH="/home/user/backup/"
KEEP_FILES=10
TARGET_EXTENSION="wpress"  # Target only .wpress files

# DRY RUN MODE - Set to false to actually delete files
DRY_RUN=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}rclone-yandex-cleanup v1.0.0${NC}"
echo -e "${GREEN}Yandex Disk Backup Management System${NC}"
echo "================================================"

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🔍 DRY RUN MODE - No files will be deleted${NC}"
    echo -e "${YELLOW}   To actually delete files, change DRY_RUN=false in the script${NC}"
else
    echo -e "${RED}⚠️  LIVE MODE - Files will be deleted${NC}"
fi

echo -e "${BLUE}Target: .$TARGET_EXTENSION files only${NC}"
echo ""

# First, upload new backups
echo -e "${YELLOW}Uploading new backups...${NC}"
rclone copy "$LOCAL_BACKUP_PATH" "${REMOTE_NAME}:${REMOTE_PATH}" --progress --timeout 60m

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Upload completed successfully${NC}"
else
    echo -e "${RED}Upload failed. Exiting...${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Starting cleanup process for .${TARGET_EXTENSION} files...${NC}"
echo "Keeping only the last $KEEP_FILES .${TARGET_EXTENSION} files for each website"
echo ""

# Get list of all website directories
WEBSITES=$(rclone lsd "${REMOTE_NAME}:${REMOTE_PATH}" 2>/dev/null | awk '{print $5}')

# Process each website directory
while IFS= read -r WEBSITE; do
    if [ -z "$WEBSITE" ]; then
        continue
    fi
    
    echo -e "${GREEN}Processing: $WEBSITE${NC}"
    
    # Create temp file for this website's files
    TEMP_FILE="/tmp/backup_cleanup_$$_${RANDOM}.tmp"
    
    # Get all .wpress files, extract just the filename from the format
    rclone lsf "${REMOTE_NAME}:${REMOTE_PATH}/${WEBSITE}" \
        --files-only \
        --include "*.${TARGET_EXTENSION}" \
        --format "tsp" 2>/dev/null | \
        sort -t$'\t' -k1 -r | \
        cut -f2 | \
        sed 's/^[^;]*;//g' | \
        sed 's/^[^;]*;//g' > "$TEMP_FILE"
    
    # Count total files
    if [ -f "$TEMP_FILE" ]; then
        TOTAL_FILES=$(wc -l < "$TEMP_FILE" | tr -d ' ')
    else
        TOTAL_FILES=0
    fi
    
    if [ "$TOTAL_FILES" -eq 0 ]; then
        echo "  No .${TARGET_EXTENSION} files found in this directory"
    elif [ "$TOTAL_FILES" -le "$KEEP_FILES" ]; then
        echo "  Found $TOTAL_FILES .${TARGET_EXTENSION} file(s) (keeping all, less than or equal to $KEEP_FILES)"
    else
        echo "  Found $TOTAL_FILES .${TARGET_EXTENSION} file(s)"
        
        # Delete older files (keep only the newest KEEP_FILES)
        DELETE_COUNT=$((TOTAL_FILES - KEEP_FILES))
        echo "  Will delete $DELETE_COUNT old .${TARGET_EXTENSION} backup(s)..."
        
        # Show which files will be kept
        echo -e "  ${BLUE}Keeping these files:${NC}"
        head -n "$KEEP_FILES" "$TEMP_FILE" | while IFS= read -r FILE_TO_KEEP; do
            if [ ! -z "$FILE_TO_KEEP" ]; then
                echo "    ✓ $FILE_TO_KEEP"
            fi
        done
        
        echo -e "  ${YELLOW}Files to delete:${NC}"
        tail -n +"$((KEEP_FILES + 1))" "$TEMP_FILE" | while IFS= read -r FILE_TO_DELETE; do
            if [ ! -z "$FILE_TO_DELETE" ]; then
                # Double-check that we're only deleting .wpress files
                if [[ "$FILE_TO_DELETE" == *.${TARGET_EXTENSION} ]]; then
                    if [ "$DRY_RUN" = true ]; then
                        echo -e "    × $FILE_TO_DELETE ... ${YELLOW}[DRY RUN - Would DELETE]${NC}"
                    else
                        echo -n "    × $FILE_TO_DELETE ... "
                        if rclone delete "${REMOTE_NAME}:${REMOTE_PATH}/${WEBSITE}/${FILE_TO_DELETE}" 2>/dev/null; then
                            echo -e "${GREEN}DELETED${NC}"
                        else
                            echo -e "${RED}FAILED${NC}"
                        fi
                    fi
                else
                    echo -e "    × $FILE_TO_DELETE ... ${RED}SKIPPED (not a .${TARGET_EXTENSION} file)${NC}"
                fi
            fi
        done
    fi
    
    # Clean up temp file
    rm -f "$TEMP_FILE"
    
    # Show count of other files in directory (non-.wpress)
    OTHER_FILES=$(rclone lsf "${REMOTE_NAME}:${REMOTE_PATH}/${WEBSITE}" \
                  --files-only \
                  --exclude "*.${TARGET_EXTENSION}" 2>/dev/null | wc -l)
    
    if [ "$OTHER_FILES" -gt 0 ]; then
        echo -e "  ${BLUE}Note: $OTHER_FILES non-.${TARGET_EXTENSION} file(s) preserved${NC}"
    fi
    
    echo ""
done <<< "$WEBSITES"

echo -e "${GREEN}Cleanup completed!${NC}"
echo ""

# Show summary of .wpress files
echo -e "${YELLOW}Summary of .${TARGET_EXTENSION} files:${NC}"
while IFS= read -r WEBSITE; do
    if [ -z "$WEBSITE" ]; then
        continue
    fi
    
    COUNT=$(rclone lsf "${REMOTE_NAME}:${REMOTE_PATH}/${WEBSITE}" \
            --files-only \
            --include "*.${TARGET_EXTENSION}" 2>/dev/null | wc -l)
    
    if [ "$COUNT" -gt 0 ]; then
        SIZE_JSON=$(rclone size "${REMOTE_NAME}:${REMOTE_PATH}/${WEBSITE}" \
               --include "*.${TARGET_EXTENSION}" --json 2>/dev/null)
        
        if [ ! -z "$SIZE_JSON" ] && command -v python3 >/dev/null 2>&1; then
            SIZE=$(echo "$SIZE_JSON" | python3 -c "import sys, json; data=json.load(sys.stdin); print(f\"{data['bytes']/1024/1024:.1f}\")" 2>/dev/null)
            if [ ! -z "$SIZE" ]; then
                echo "  $WEBSITE: $COUNT .${TARGET_EXTENSION} files (${SIZE} MB)"
            else
                echo "  $WEBSITE: $COUNT .${TARGET_EXTENSION} files"
            fi
        else
            echo "  $WEBSITE: $COUNT .${TARGET_EXTENSION} files"
        fi
    fi
done <<< "$WEBSITES"

echo ""
echo -e "${YELLOW}Total disk usage:${NC}"
TOTAL_JSON=$(rclone size "${REMOTE_NAME}:${REMOTE_PATH}" --json 2>/dev/null)
if [ ! -z "$TOTAL_JSON" ] && command -v python3 >/dev/null 2>&1; then
    echo "$TOTAL_JSON" | python3 -c "import sys, json; data=json.load(sys.stdin); print(f\"  All files: {data['count']} files, {data['bytes']/1024/1024/1024:.2f} GB\")" 2>/dev/null
else
    rclone size "${REMOTE_NAME}:${REMOTE_PATH}"
fi

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}This was a DRY RUN - no files were actually deleted${NC}"
    echo -e "${YELLOW}To perform actual deletion, edit the script and set:${NC}"
    echo -e "${YELLOW}  DRY_RUN=false${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
fi

# Release lock (happens automatically on exit, but being explicit)
flock -u 99