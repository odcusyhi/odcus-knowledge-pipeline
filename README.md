# ODCUS Knowledge Pipeline

A self-maintaining knowledge base for consulting work — built on three connected ideas: AI as librarian, automatic document ingestion, and local semantic search. You drop files. The system handles everything else.

---

## The problem it solves

Knowledge work produces enormous amounts of input: research papers, client presentations, industry reports, meeting notes, competitor materials, regulatory documents. The usual outcome is a graveyard of PDFs nobody searches, or a wiki nobody maintains.

This system solves both problems:

- **No manual filing** — drop a file, it gets converted and ingested automatically
- **No manual wiki maintenance** — AI reads the raw material and updates structured articles
- **No hunting for files** — Claude can search the knowledge base semantically in any session

The result: a knowledge base that grows with every document you add, and that Claude can actually use without being pointed to specific files.

---

## How it works

```
┌─────────────────────────────────────────────────────────┐
│                     INPUT LAYER                         │
│                                                         │
│  Drop any file into:                                    │
│  OneDrive → ODCUS General → Knowledge Process/         │
│                                                         │
│  Supported: PDF, DOCX, PPTX, XLSX, HTML, TXT, CSV, MD  │
└─────────────────────┬───────────────────────────────────┘
                      │ file appears (fswatch event)
                      ▼
┌─────────────────────────────────────────────────────────┐
│                  CONVERSION LAYER                       │
│                                                         │
│  watcher.sh (runs 24/7 via launchd)                    │
│                                                         │
│  1. Validates file (type, size, no symlinks)            │
│  2. Converts to Markdown via markitdown (Microsoft)     │
│  3. Saves .md to knowhow/raw/                           │
│  4. Moves original to Library/ (OneDrive archive)       │
└─────────────────────┬───────────────────────────────────┘
                      │ .md file in raw/
                      ▼
┌─────────────────────────────────────────────────────────┐
│                  CURATION LAYER                         │
│                                                         │
│  /odcus-kb-compile  (Claude Code skill)                 │
│                                                         │
│  Claude reads raw/ files and:                           │
│  - Routes each to the right discipline folder           │
│  - Merges new info into existing articles               │
│  - Updates the master index                             │
│  - Flags gaps and contradictions                        │
│                                                         │
│  knowhow/                                               │
│    cyber/        compliance/     finops/                │
│    sourcing/     modernization/  ai/    managed/        │
└─────────────────────┬───────────────────────────────────┘
                      │ structured .md articles
                      ▼
┌─────────────────────────────────────────────────────────┐
│                   SEARCH LAYER                          │
│                                                         │
│  QMD — local semantic search MCP server                 │
│                                                         │
│  Indexes all articles. In any Claude Code session,      │
│  Claude queries the KB automatically:                   │
│                                                         │
│  - BM25 (keyword)                                       │
│  - Vector (semantic)                                    │
│  - HyDE (hypothetical document)                         │
│                                                         │
│  No data leaves your machine.                           │
└─────────────────────────────────────────────────────────┘
```

---

## Components

| Component | What it is | Role |
|-----------|-----------|------|
| `watcher.sh` | zsh script + launchd service | Watches drop folder, converts files to Markdown |
| `markitdown` | Microsoft open-source tool | Converts PDF/DOCX/PPTX/XLSX/HTML → Markdown |
| `fswatch` | macOS file system watcher | Triggers conversion when a new file appears |
| `/odcus-kb-compile` | Claude Code skill | Reads raw/ and writes structured wiki articles |
| `/odcus-kb-healthcheck` | Claude Code skill | Finds gaps, stale facts, unprocessed files |
| `qmd` | Local MCP search server | Indexes markdown, serves semantic search to Claude |
| Obsidian | Markdown editor + sync | Readable interface for the knowledge base |

---

## Folder layout

```
OneDrive (shared)
├── Knowledge Process/    ← drop files here
└── Library/              ← originals archived here after conversion

Obsidian vault (iCloud)
└── 02-operations/knowhow/
    ├── raw/              ← converted .md files land here
    ├── cyber/            ← curated wiki: cybersecurity
    ├── compliance/       ← curated wiki: compliance & regulation
    ├── finops/           ← curated wiki: cloud cost management
    ├── sourcing/         ← curated wiki: vendor & procurement
    ├── modernization/    ← curated wiki: legacy & cloud migration
    ├── ai/               ← curated wiki: AI adoption & governance
    ├── managed/          ← curated wiki: managed services
    ├── references/       ← source PDFs and reference files
    └── _index.md         ← master index, auto-maintained
```

---

## Day-to-day usage

**Adding knowledge:**
1. Drop a file into `OneDrive → Knowledge Process/`
2. Wait a few seconds — it converts automatically
3. Open Claude Code, run `/odcus-kb-compile`
4. Done. The article is in the wiki and searchable.

**Querying the knowledge base:**
- Just ask Claude in any session: "what do we know about NIS2 for Swiss manufacturers?"
- Claude searches QMD automatically and pulls relevant passages

**Maintenance:**
- Run `/odcus-kb-healthcheck` occasionally to find gaps, stale entries, and unprocessed files

---

## Philosophy

The system is built on two ideas:

**Karpathy-style KB** — Andrej Karpathy's approach to knowledge management: the AI is the librarian, not you. You collect raw material. The AI reads, structures, and maintains the wiki. You never edit articles directly.

**QMD by Tobi Lütke** — Shopify's CEO on AI-augmented work: documents should be *queryable*, not just *searchable*. QMD makes your markdown knowledge base queryable with the same semantics as a database, accessible to Claude in real time.

Full details: [docs/philosophy.md](docs/philosophy.md)

---

## Documentation

| Doc | Contents |
|-----|---------|
| [docs/philosophy.md](docs/philosophy.md) | The ideas behind the system |
| [docs/qmd-setup.md](docs/qmd-setup.md) | Installing and configuring QMD |
| [docs/pipeline-setup.md](docs/pipeline-setup.md) | Full pipeline installation guide |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Common issues and fixes |
| [pipeline/watcher.sh](pipeline/watcher.sh) | The file watcher script |
| [pipeline/com.odcus.knowhow-watcher.plist](pipeline/com.odcus.knowhow-watcher.plist) | launchd service config |

---

## Quick start

```bash
# 1. Install dependencies
brew install fswatch
curl -LsSf https://astral.sh/uv/install.sh | sh

# 2. Copy and configure the watcher script
cp pipeline/watcher.sh ~/.local/bin/odcus-knowhow-watcher.sh
chmod +x ~/.local/bin/odcus-knowhow-watcher.sh
# Edit WATCH_DIR, OUTPUT_DIR, ARCHIVE_DIR at the top of the script

# 3. Install the background service
cp pipeline/com.odcus.knowhow-watcher.plist ~/Library/LaunchAgents/
# Edit paths in the plist to match your username
launchctl load ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist

# 4. Configure QMD (see docs/qmd-setup.md)

# 5. Verify
launchctl list | grep odcus          # should show a PID
tail -f ~/.local/logs/odcus-knowhow-watcher.log  # watch for activity
```

Full instructions: [docs/pipeline-setup.md](docs/pipeline-setup.md)
