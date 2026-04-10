#!/bin/zsh

WATCH_DIR="/Users/yannickhirt/Library/CloudStorage/OneDrive-SharedLibraries-ODCUS/ODCUS - General/Knowledge Process"
OUTPUT_DIR="/Users/yannickhirt/Library/Mobile Documents/iCloud~md~obsidian/Documents/ODCUS/02-operations/knowhow/raw"
ARCHIVE_DIR="/Users/yannickhirt/Library/CloudStorage/OneDrive-SharedLibraries-ODCUS/ODCUS - General/Library"

LOG="$HOME/.local/logs/odcus-knowhow-watcher.log"
mkdir -p "$(dirname "$LOG")"

ALLOWED_EXTENSIONS=("pdf" "docx" "pptx" "xlsx" "txt" "html" "md" "csv")
MAX_FILE_SIZE=104857600  # 100 MB

log() {
  # Rotate log if over 10 MB
  if [[ -f "$LOG" ]] && (( $(stat -f%z "$LOG" 2>/dev/null || echo 0) > 10485760 )); then
    mv "$LOG" "$LOG.old"
  fi
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"
}

process_file() {
  local filepath="$1"

  # Skip hidden and temp files
  local filename="$(basename "$filepath")"
  [[ "$filename" == .* ]] && return
  [[ "$filename" == ~* ]] && return

  # Skip directories
  [[ -d "$filepath" ]] && return

  # Skip symlinks — prevents local file exfiltration via crafted OneDrive drops
  if [[ -L "$filepath" ]]; then
    log "SKIP symlink: $filename"
    return
  fi

  # Only process files directly in the watch dir (not subdirs)
  local parent="$(dirname "$filepath")"
  [[ "$parent" != "$WATCH_DIR" ]] && return

  # Extension allowlist
  local ext="${filename##*.}"
  ext="${(L)ext}"  # lowercase (zsh)
  if (( ! ${ALLOWED_EXTENSIONS[(Ie)$ext]} )); then
    log "SKIP unsupported extension (.${ext}): $filename"
    return
  fi

  # Wait briefly for file to finish writing
  sleep 2

  # Re-check: skip if file no longer exists
  [[ ! -f "$filepath" ]] && return

  # Re-check: skip symlinks that may have been swapped in during sleep (TOCTOU)
  if [[ -L "$filepath" ]]; then
    log "SKIP symlink (post-sleep): $filename"
    return
  fi

  # Ensure resolved path is still inside the watch dir (no path escape)
  local resolved="$(realpath "$filepath" 2>/dev/null)"
  if [[ "$resolved" != "$WATCH_DIR/"* ]]; then
    log "SKIP path escape: $filename → $resolved"
    return
  fi

  # File size cap (100 MB)
  local filesize=$(stat -f%z "$filepath" 2>/dev/null || echo 0)
  if (( filesize > MAX_FILE_SIZE )); then
    log "SKIP too large (${filesize} bytes): $filename"
    return
  fi

  local basename_no_ext="${filename%.*}"
  local output_file="$OUTPUT_DIR/${basename_no_ext}.md"

  log "Processing: $filename (${filesize} bytes)"

  # Convert to markdown
  if uvx markitdown "$filepath" > "$output_file" 2>> "$LOG"; then
    log "Saved markdown: $output_file"
    mv "$filepath" "$ARCHIVE_DIR/$filename"
    log "Moved original to Library: $filename"
  else
    log "ERROR: Conversion failed for $filename"
    rm -f "$output_file"
  fi
}

log "Watcher started. Watching: $WATCH_DIR"

/opt/homebrew/bin/fswatch \
  --event Created \
  --event Renamed \
  --event MovedTo \
  --latency 1 \
  --exclude '^\.' \
  "$WATCH_DIR" | while read -r changed_path; do
    process_file "$changed_path"
  done
