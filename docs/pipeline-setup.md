# Pipeline Setup

The ingestion pipeline watches a folder for new files, converts them to Markdown, saves them to the knowledge base intake folder, and moves the original to an archive. It runs as a macOS background service — no manual steps required after setup.

---

## How it works

```
You drop a file
    ↓
fswatch detects the new file (within ~1 second)
    ↓
watcher.sh runs security checks:
  - not a symlink
  - extension on allowlist
  - under 100 MB
  - resolved path inside watch dir
    ↓
markitdown converts the file to Markdown
    ↓
.md saved to knowledge-base/raw/
    ↓
original moved to archive/
    ↓
ready for /odcus-kb-compile
```

The watcher runs continuously as a launchd service — starts on login, stays running, restarts automatically if it crashes.

---

## Prerequisites

**macOS** — the pipeline uses `launchd` for service management and `fswatch` for file watching. Linux would need systemd and inotifywait instead.

**Homebrew**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**uv / uvx** — runs markitdown without a permanent install
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**fswatch**
```bash
brew install fswatch
```

Verify both:
```bash
which fswatch
uvx markitdown --help
```

---

## Folder setup

You need three locations:

| Location | Role |
|----------|------|
| **Drop zone** | Where you put files to be processed |
| **Raw intake** | Where converted `.md` files are saved |
| **Archive** | Where originals are moved after conversion |

These can be local folders, cloud-synced folders (OneDrive, Dropbox), or a mix. The raw intake should live inside a folder that syncs to your other devices — typically your Obsidian vault.

Create all three before running setup:

```bash
mkdir -p "/path/to/drop-zone"
mkdir -p "/path/to/knowledge-base/raw"
mkdir -p "/path/to/archive"
```

---

## Installation

### Step 1 — Copy and configure the watcher script

```bash
mkdir -p ~/.local/bin
cp pipeline/watcher.sh ~/.local/bin/knowhow-watcher.sh
chmod +x ~/.local/bin/knowhow-watcher.sh
```

Open the script and set the three path variables at the top:

```bash
WATCH_DIR="/path/to/your/drop-zone"
OUTPUT_DIR="/path/to/your/knowledge-base/raw"
ARCHIVE_DIR="/path/to/your/archive"
```

Use absolute paths. Do not use `~` — launchd does not expand it.

**Example with iCloud + OneDrive:**
```bash
WATCH_DIR="/Users/yourname/Library/CloudStorage/OneDrive-Company/Shared/incoming"
OUTPUT_DIR="/Users/yourname/Library/Mobile Documents/iCloud~md~obsidian/Documents/Vault/knowledge-base/raw"
ARCHIVE_DIR="/Users/yourname/Library/CloudStorage/OneDrive-Company/Shared/archive"
```

**Example with local folders only:**
```bash
WATCH_DIR="/Users/yourname/Documents/kb-incoming"
OUTPUT_DIR="/Users/yourname/Documents/knowledge-base/raw"
ARCHIVE_DIR="/Users/yourname/Documents/kb-archive"
```

### Step 2 — Configure the launchd service

```bash
cp pipeline/com.odcus.knowhow-watcher.plist ~/Library/LaunchAgents/
```

Open the plist and replace `YOUR_USERNAME` with your macOS username in all three places:

```bash
# Quick replace (substitute yourname)
sed -i '' 's/YOUR_USERNAME/yourname/g' ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist
```

### Step 3 — Create the log directory

```bash
mkdir -p ~/.local/logs
```

### Step 4 — Load the service

```bash
launchctl load ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist
```

### Step 5 — Verify

```bash
launchctl list | grep odcus
```

A number in the first column means the process is running:

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

Within a few seconds:

```
[2026-04-10 14:25:03] Processing: report.pdf (1243891 bytes)
[2026-04-10 14:25:07] Saved markdown: /path/to/knowledge-base/raw/report.md
[2026-04-10 14:25:07] Moved original to archive: report.pdf
```

Confirm `report.md` is in `knowledge-base/raw/` and `report.pdf` is in the archive.

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

## After a file is converted

The `.md` file lands in `knowledge-base/raw/`. From there, run the compile skill in Claude Code to integrate it into the structured wiki:

```
/odcus-kb-compile
```

Claude reads all new files in `raw/`, routes them to the right discipline folder, merges information into existing articles, and updates the master index.

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

| Log entry | Meaning |
|-----------|---------|
| `Watcher started` | Service launched |
| `Processing: file.pdf` | Conversion started |
| `Saved markdown: file.md` | Conversion succeeded |
| `Moved original to archive` | Original archived |
| `SKIP symlink` | Symlink rejected |
| `SKIP unsupported extension` | Extension not on allowlist |
| `SKIP too large` | File over 100 MB |
| `SKIP path escape` | Resolved path outside watch dir |
| `ERROR: Conversion failed` | markitdown error |

Log rotates automatically at 10 MB.

---

## Security

**Symlink attacks** — a symlink in the drop zone could point to any file on your machine. The watcher rejects all symlinks immediately and re-checks after the 2-second wait.

**Path traversal** — `realpath` resolves the actual path before processing. Anything resolving outside `WATCH_DIR/` is rejected.

**Oversized files** — files over 100 MB are skipped.

**Unsupported types** — only allowlisted extensions are processed.

If your drop zone is a shared folder (team OneDrive, shared Dropbox), anyone with write access can trigger processing. Review who has access and adjust the allowlist accordingly.
