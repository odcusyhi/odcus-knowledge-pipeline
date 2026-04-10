# Pipeline Setup

The ingestion pipeline watches a folder for new files, converts them to Markdown, saves them to the knowledge base intake folder, and moves the original to an archive. It runs as a macOS background service — fully automatic after initial setup.

---

## How it works

```
You drop a file into the drop zone
    ↓
fswatch detects it within ~1 second
    ↓
watcher.sh validates the file:
  ✓ not a symlink
  ✓ extension on allowlist
  ✓ under 100 MB
  ✓ resolved path inside watch dir
    ↓
uvx markitdown converts the file to Markdown
    ↓
.md saved to knowledge-base/raw/
    ↓
original moved to archive/
    ↓
ready for /kb-compile
```

The watcher runs as a launchd service — starts on login, stays running, restarts automatically if it crashes.

---

## Prerequisites

**macOS** — uses `launchd` and `fswatch`. Linux requires systemd and inotifywait instead.

### Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### fswatch

```bash
brew install fswatch
```

### uv / uvx (for markitdown)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Verify both are available:

```bash
which fswatch
uvx markitdown --help
```

---

## Folder setup

You need three locations. Create them before running setup:

| Folder | Role | Recommended location |
|--------|------|---------------------|
| **Drop zone** | Where you put files to process | Cloud-synced folder (OneDrive, Dropbox) or local |
| **Raw intake** | Where converted `.md` files land | Inside your Obsidian vault or knowledge base folder |
| **Archive** | Where originals go after conversion | Same cloud storage as drop zone |

```bash
mkdir -p "/path/to/drop-zone"
mkdir -p "/path/to/knowledge-base/raw"
mkdir -p "/path/to/archive"
```

---

## Installation

### 1. Copy and configure the watcher script

```bash
mkdir -p ~/.local/bin ~/.local/logs
cp pipeline/watcher.sh ~/.local/bin/knowhow-watcher.sh
chmod +x ~/.local/bin/knowhow-watcher.sh
```

Edit the three variables at the top of `~/.local/bin/knowhow-watcher.sh`:

```bash
WATCH_DIR="/path/to/your/drop-zone"
OUTPUT_DIR="/path/to/your/knowledge-base/raw"
ARCHIVE_DIR="/path/to/your/archive"
```

Use absolute paths only — no `~` (launchd doesn't expand it).

**Example with iCloud + OneDrive:**
```bash
WATCH_DIR="/Users/yourname/Library/CloudStorage/OneDrive-Company/Shared/incoming"
OUTPUT_DIR="/Users/yourname/Library/Mobile Documents/iCloud~md~obsidian/Documents/Vault/knowledge-base/raw"
ARCHIVE_DIR="/Users/yourname/Library/CloudStorage/OneDrive-Company/Shared/archive"
```

**Example with local folders:**
```bash
WATCH_DIR="/Users/yourname/Documents/kb-incoming"
OUTPUT_DIR="/Users/yourname/Documents/knowledge-base/raw"
ARCHIVE_DIR="/Users/yourname/Documents/kb-archive"
```

### 2. Install the launchd service

```bash
cp pipeline/com.odcus.knowhow-watcher.plist ~/Library/LaunchAgents/

# Replace YOUR_USERNAME with your macOS username
sed -i '' "s/YOUR_USERNAME/$(whoami)/g" ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist
```

### 3. Load the service

```bash
launchctl load ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist
```

### 4. Verify

```bash
launchctl list | grep odcus
```

A number (not a dash) in the first column means the process is running:

```
73463   0   com.odcus.knowhow-watcher
```

Check the log:

```bash
tail ~/.local/logs/knowhow-watcher.log
# Expected: [2026-04-10 14:23:01] Watcher started. Watching: /path/to/drop-zone
```

---

## Testing

Drop a supported file into the drop zone and watch the log:

```bash
tail -f ~/.local/logs/knowhow-watcher.log
```

Within a few seconds you should see:

```
[2026-04-10 14:25:03] Processing: report.pdf (1243891 bytes)
[2026-04-10 14:25:07] Saved markdown: /path/to/knowledge-base/raw/report.md
[2026-04-10 14:25:07] Moved original to archive: report.pdf
```

---

## Supported file types

| Extension | Format |
|-----------|--------|
| `pdf` | PDF documents |
| `docx` | Word documents |
| `pptx` | PowerPoint presentations |
| `xlsx` | Excel spreadsheets |
| `html` | Web pages |
| `txt` | Plain text |
| `md` | Markdown (pass-through) |
| `csv` | Comma-separated values |

To add more types, edit `ALLOWED_EXTENSIONS` in `watcher.sh`:

```bash
ALLOWED_EXTENSIONS=("pdf" "docx" "pptx" "xlsx" "txt" "html" "md" "csv" "epub")
```

---

## After conversion

The converted `.md` lands in `knowledge-base/raw/`. From there, run the compile skill in Claude Code:

```
/kb-compile
```

Claude routes each file to the right discipline folder, merges it into existing articles or creates new ones, and updates the search index.

---

## Service management

```bash
# Check status
launchctl list | grep odcus

# Stop
launchctl unload ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist

# Start
launchctl load ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist

# Restart (required after editing watcher.sh)
launchctl unload ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist
launchctl load ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist
```

---

## Logs

```bash
tail -f ~/.local/logs/knowhow-watcher.log   # stream live
tail -20 ~/.local/logs/knowhow-watcher.log  # last 20 lines
```

| Entry | Meaning |
|-------|---------|
| `Watcher started` | Service launched |
| `Processing: file.pdf` | Conversion started |
| `Saved markdown: file.md` | Conversion succeeded |
| `Moved original to archive` | Original archived |
| `SKIP symlink` | Symlink rejected |
| `SKIP unsupported extension` | Not on allowlist |
| `SKIP too large` | Over 100 MB |
| `SKIP path escape` | Resolved path outside watch dir |
| `ERROR: Conversion failed` | markitdown returned an error |

Log rotates at 10 MB.

---

## Security

If your drop zone is a shared folder, anyone with write access can trigger processing on your machine. The watcher defends against the main risks:

**Symlink attacks** — a symlink in the drop zone could point to any local file. The watcher rejects all symlinks immediately and re-checks after the 2-second write wait.

**Path traversal** — `realpath` resolves the actual path. Anything resolving outside `WATCH_DIR/` is rejected.

**Oversized files** — files over 100 MB are skipped.

**Unsupported types** — only allowlisted extensions are processed.
