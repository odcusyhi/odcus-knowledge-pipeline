# Pipeline Setup

The ingestion pipeline watches a folder for new files, converts them to Markdown, saves them to the knowledge base intake folder, and moves the original to an archive. It runs as a macOS background service — no manual steps required after setup.

## Prerequisites

- macOS (uses `launchd` for background service management)
- [Homebrew](https://brew.sh)
- `uvx` (part of `uv` — fast Python package runner)

```bash
# Install uv if not already installed
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install fswatch
brew install fswatch
```

## Folder structure

| Folder | Purpose |
|--------|---------|
| `Knowledge Process/` | **Drop zone** — put files here |
| `knowhow/raw/` | **Intake** — converted `.md` files land here |
| `Library/` | **Archive** — originals moved here after conversion |

In this setup:
- `Knowledge Process/` and `Library/` are shared OneDrive folders
- `knowhow/raw/` is the Obsidian vault (iCloud-synced)

## Installation

### 1. Copy the script

```bash
cp pipeline/watcher.sh ~/.local/bin/odcus-knowhow-watcher.sh
chmod +x ~/.local/bin/odcus-knowhow-watcher.sh
```

Edit the three path variables at the top of the script to match your environment:

```bash
WATCH_DIR="..."   # folder to watch (drop zone)
OUTPUT_DIR="..."  # where .md files are saved
ARCHIVE_DIR="..."  # where originals are moved after conversion
```

### 2. Install the launchd service

```bash
cp pipeline/com.odcus.knowhow-watcher.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist
```

The service starts immediately and automatically on every login.

### 3. Verify it's running

```bash
launchctl list | grep odcus
```

You should see a PID (non-zero number) in the first column.

## How it works

1. `fswatch` watches the drop zone for new files (Created, Renamed, MovedTo events)
2. When a file appears, the script:
   - Rejects symlinks (security: prevents exfiltration of local files via OneDrive)
   - Validates file extension against an allowlist
   - Rejects files over 100 MB
   - Waits 2 seconds for the file to finish writing
   - Validates the resolved path is still inside the watch directory (TOCTOU protection)
   - Runs `uvx markitdown <file>` to convert to Markdown
   - Saves output to `knowhow/raw/<filename>.md`
   - Moves the original to `Library/`

## Supported file types

```
pdf  docx  pptx  xlsx  txt  html  md  csv
```

All other extensions are skipped and logged.

## Logs

```bash
# Follow live
tail -f ~/.local/logs/odcus-knowhow-watcher.log

# Last 20 lines
tail -20 ~/.local/logs/odcus-knowhow-watcher.log
```

Log rotates automatically at 10 MB.

## After a file is converted

The converted `.md` lands in `knowhow/raw/`. From there, run the compile skill in Claude Code to integrate it into the structured knowledge base:

```
/odcus-kb-compile
```

Claude will read the new files, route them to the right discipline folder, update existing articles, and re-index for QMD search.

## Service management

```bash
# Stop
launchctl unload ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist

# Start
launchctl load ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist

# Restart (after editing the script)
launchctl unload ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist
launchctl load ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist
```

## Security notes

The drop zone is a shared OneDrive folder. Anyone with write access to that folder can trigger file processing on your machine. The script guards against:

- **Symlink attacks** — symlinks are rejected outright; a collaborator cannot use them to exfiltrate local files
- **Path traversal** — resolved path must remain inside the watch directory
- **Oversized files** — files over 100 MB are skipped
- **Unsupported types** — only allowlisted extensions are processed

If you cannot fully control who writes to the OneDrive folder, treat this as a trust boundary and review the allowed extensions accordingly.
