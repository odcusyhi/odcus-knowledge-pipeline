# Pipeline Setup

The ingestion pipeline converts any supported document into Markdown the moment it lands in a OneDrive folder, saves the result to the knowledge base intake folder, and moves the original to an archive. It runs as a macOS background service — no manual steps required after initial setup.

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
.md saved to knowhow/raw/
    ↓
original moved to Library/ (OneDrive archive)
    ↓
ready for /odcus-kb-compile
```

The watcher runs continuously as a launchd service — it starts on login, stays running, and restarts automatically if it crashes.

---

## Prerequisites

**macOS** — the pipeline uses `launchd` for service management and `fswatch` for file watching. Linux would need systemd and inotifywait instead.

**Homebrew** — for installing fswatch:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**uv / uvx** — for running markitdown without a permanent install:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Verify both are working:
```bash
which fswatch        # should return a path
uvx markitdown --help  # should print usage
```

---

## Folder setup

You need three folders:

| Folder | Role | Where |
|--------|------|-------|
| Drop zone | You put files here | Shared OneDrive |
| Intake | Converted `.md` files appear here | Obsidian vault / iCloud |
| Archive | Originals moved here after conversion | Shared OneDrive |

The drop zone and archive can be any folder — local, OneDrive, Dropbox. The intake folder should be inside your Obsidian vault so it syncs via iCloud and stays accessible across devices.

Make sure all three folders exist before running the setup:

```bash
mkdir -p "/path/to/drop-zone"
mkdir -p "/path/to/knowhow/raw"
mkdir -p "/path/to/archive"
```

---

## Installation

### Step 1 — Copy and configure the watcher script

```bash
mkdir -p ~/.local/bin
cp pipeline/watcher.sh ~/.local/bin/odcus-knowhow-watcher.sh
chmod +x ~/.local/bin/odcus-knowhow-watcher.sh
```

Open the script and set the three path variables at the top:

```bash
WATCH_DIR="/path/to/your/drop-zone"
OUTPUT_DIR="/path/to/your/knowhow/raw"
ARCHIVE_DIR="/path/to/your/archive"
```

Use absolute paths. Do not use `~` — launchd doesn't expand it.

Example (OneDrive + iCloud):
```bash
WATCH_DIR="/Users/yourname/Library/CloudStorage/OneDrive-SharedLibraries-Company/Company - General/Knowledge Process"
OUTPUT_DIR="/Users/yourname/Library/Mobile Documents/iCloud~md~obsidian/Documents/Vault/knowhow/raw"
ARCHIVE_DIR="/Users/yourname/Library/CloudStorage/OneDrive-SharedLibraries-Company/Company - General/Library"
```

### Step 2 — Configure the launchd service

```bash
cp pipeline/com.odcus.knowhow-watcher.plist ~/Library/LaunchAgents/
```

Open `~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist` and update the username in the script path:

```xml
<string>/Users/yourname/.local/bin/odcus-knowhow-watcher.sh</string>
```

Also update the log paths:

```xml
<string>/Users/yourname/.local/logs/odcus-knowhow-watcher.log</string>
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

The first column is the PID. A number (not a dash) means the process is running:

```
73463   0   com.odcus.knowhow-watcher
```

Check the log to confirm the watcher started:

```bash
tail ~/.local/logs/odcus-knowhow-watcher.log
```

You should see:
```
[2026-04-10 14:23:01] Watcher started. Watching: /path/to/drop-zone
```

---

## Testing

Drop a supported file into the watch folder and observe the log:

```bash
tail -f ~/.local/logs/odcus-knowhow-watcher.log
```

Within a few seconds you should see:

```
[2026-04-10 14:25:03] Processing: report.pdf (1243891 bytes)
[2026-04-10 14:25:07] Saved markdown: /path/to/knowhow/raw/report.md
[2026-04-10 14:25:07] Moved original to Library: report.pdf
```

Check that `report.md` appeared in `knowhow/raw/` and that `report.pdf` is now in `Library/`.

---

## Supported file types

The following extensions are on the allowlist. All others are skipped with a log entry.

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

To add more types, edit the `ALLOWED_EXTENSIONS` array in `watcher.sh`:

```bash
ALLOWED_EXTENSIONS=("pdf" "docx" "pptx" "xlsx" "txt" "html" "md" "csv" "epub")
```

---

## After a file is converted

The converted `.md` file lands in `knowhow/raw/` with the same filename (minus the original extension). From there, the file needs to be curated into the structured wiki by running the compile skill in Claude Code:

```
/odcus-kb-compile
```

Claude reads all new files in `raw/`, determines which discipline each belongs to, and either creates a new article or merges the information into an existing one. It then updates `_index.md`.

Run this after adding a batch of files — there's no need to compile after every single drop.

---

## Service management

```bash
# Check status
launchctl list | grep odcus

# Stop the service
launchctl unload ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist

# Start the service
launchctl load ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist

# Restart (required after editing watcher.sh)
launchctl unload ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist
launchctl load ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist
```

The service is configured with `KeepAlive: true` — if the script crashes, launchd restarts it automatically.

---

## Logs

```bash
# Stream live
tail -f ~/.local/logs/odcus-knowhow-watcher.log

# Last 20 lines
tail -20 ~/.local/logs/odcus-knowhow-watcher.log
```

Log entries:

| Entry | Meaning |
|-------|---------|
| `Watcher started` | Service launched successfully |
| `Processing: file.pdf` | Conversion started |
| `Saved markdown: file.md` | Conversion succeeded |
| `Moved original to Library` | Original archived |
| `SKIP symlink` | File was a symlink — rejected |
| `SKIP unsupported extension` | Extension not on allowlist |
| `SKIP too large` | File exceeds 100 MB cap |
| `SKIP path escape` | Resolved path outside watch dir — rejected |
| `ERROR: Conversion failed` | markitdown returned an error |

The log rotates automatically when it exceeds 10 MB (renamed to `.log.old`).

---

## Security

The drop zone is a shared OneDrive folder. This means any OneDrive collaborator with write access can drop files that trigger processing on your local machine. The watcher defends against the main attack vectors:

**Symlink attacks**
A malicious actor drops a symlink pointing to `~/.ssh/id_rsa`. Without protection, the script would read and convert that file to Markdown, potentially exposing it via iCloud sync. The watcher rejects all symlinks immediately — both on detection and again after the 2-second wait (in case of a symlink swap).

**Path traversal**
A filename like `../../.ssh/config` could resolve to a path outside the watch directory. The watcher uses `realpath` to resolve the actual path and rejects anything that doesn't remain inside `WATCH_DIR/`.

**Oversized files**
A 4 GB file would consume significant memory during conversion. The watcher skips files over 100 MB.

**Unsupported types**
Executable files, scripts, and other formats are not on the allowlist. They are skipped and logged.

**Recommendation:** If multiple people have write access to the OneDrive drop folder, treat it as a semi-trusted input surface. Review the allowlist and consider who has access before enabling.
