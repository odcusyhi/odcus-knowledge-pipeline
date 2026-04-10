#!/bin/zsh

# ─── Configure these three paths before running ───────────────────────────────
WATCH_DIR="/path/to/your/drop-zone"
OUTPUT_DIR="/path/to/your/knowledge-base/raw"
ARCHIVE_DIR="/path/to/your/archive"
# ──────────────────────────────────────────────────────────────────────────────

# Only owner can read/write files created by this script
umask 077

LOG="$HOME/.local/logs/knowhow-watcher.log"
mkdir -p "$(dirname "$LOG")"

ALLOWED_EXTENSIONS=("pdf" "docx" "pptx" "xlsx" "txt" "html" "md" "csv")
MAX_FILE_SIZE=104857600  # 100 MB

# ─── Startup validation ───────────────────────────────────────────────────────
for dir in "$WATCH_DIR" "$OUTPUT_DIR" "$ARCHIVE_DIR"; do
  if [[ ! -d "$dir" ]]; then
    echo "FATAL: Directory does not exist: $dir" >&2
    echo "Edit the path variables at the top of this script before running." >&2
    exit 1
  fi
done

log() {
  # Strip control characters from message to prevent log injection
  local msg="${1//[$'\x00'-$'\x1f']/_}"
  # Rotate log if over 10 MB
  if [[ -f "$LOG" ]] && (( $(stat -f%z "$LOG" 2>/dev/null || echo 0) > 10485760 )); then
    mv "$LOG" "$LOG.old"
  fi
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $msg" >> "$LOG"
}

process_file() {
  local filepath="$1"

  # Skip hidden and temp files
  local filename="$(basename "$filepath")"
  [[ "$filename" == .* ]] && return
  [[ "$filename" == ~* ]] && return

  # Skip directories
  [[ -d "$filepath" ]] && return

  # Reject filenames containing path separators or traversal sequences
  if [[ "$filename" == */* ]] || [[ "$filename" == *..* ]]; then
    log "SKIP dangerous filename: $filename"
    return
  fi

  # Skip symlinks — prevents local file exfiltration via crafted drops
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

  # Re-check: skip symlinks swapped in during sleep (TOCTOU mitigation step 1)
  if [[ -L "$filepath" ]]; then
    log "SKIP symlink (post-sleep): $filename"
    return
  fi

  # Ensure resolved path is still inside the watch dir
  local resolved="$(realpath "$filepath" 2>/dev/null)"
  if [[ "$resolved" != "$WATCH_DIR/"* ]]; then
    log "SKIP path escape: $filename"
    return
  fi

  # File size cap (100 MB)
  local filesize=$(stat -f%z "$filepath" 2>/dev/null || echo 0)
  if (( filesize > MAX_FILE_SIZE )); then
    log "SKIP too large (${filesize} bytes): $filename"
    return
  fi

  # Copy to a temp file before processing — eliminates TOCTOU race window
  local tmpfile
  tmpfile="$(mktemp "${TMPDIR:-/tmp}/knowhow.XXXXXX")" || { log "ERROR: mktemp failed"; return; }

  if ! cp -a "$filepath" "$tmpfile" 2>/dev/null; then
    log "ERROR: Failed to copy $filename to tmp"
    rm -f "$tmpfile"
    return
  fi

  # Verify the copy is not a symlink (defense in depth)
  if [[ -L "$tmpfile" ]]; then
    log "SKIP symlink in tmp copy: $filename"
    rm -f "$tmpfile"
    return
  fi

  # Sanitize stem for use in output filename (strip path separators)
  local basename_no_ext="${filename%.*}"
  basename_no_ext="${basename_no_ext//\//_}"
  basename_no_ext="${basename_no_ext//\.\./_}"

  # Add timestamp to prevent output and archive overwrites
  local ts
  ts="$(date '+%Y%m%d-%H%M%S')"
  local output_file="$OUTPUT_DIR/${basename_no_ext}.md"
  if [[ -f "$output_file" ]]; then
    output_file="$OUTPUT_DIR/${basename_no_ext}_${ts}.md"
  fi

  log "Processing: $filename (${filesize} bytes)"

  # Convert to markdown using the safe tmp copy
  if uvx markitdown "$tmpfile" > "$output_file" 2>> "$LOG"; then
    rm -f "$tmpfile"
    log "Saved markdown: $output_file"
    # Archive original with timestamp prefix to prevent overwrites
    mv "$filepath" "$ARCHIVE_DIR/${ts}_${filename}"
    log "Moved original to archive: ${ts}_${filename}"
  else
    log "ERROR: Conversion failed for $filename"
    rm -f "$tmpfile" "$output_file"
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
