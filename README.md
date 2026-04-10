# Knowledge Pipeline

An open-source architecture for a self-maintaining knowledge base — built on three connected ideas: AI as librarian, automatic document ingestion, and local semantic search.

You drop files. The system converts, curates, and indexes them. Claude uses the knowledge base automatically in every session.

Built and open-sourced by [ODCUS](https://www.odcus.com) — an IT advisory firm based in Switzerland.

---

## The idea

Knowledge work produces enormous input: research papers, client notes, industry reports, regulatory documents, competitor materials. The usual outcome is a graveyard of PDFs nobody searches, or a wiki nobody maintains.

This system solves both problems:

- **No manual filing** — drop a file, it gets converted and ingested automatically
- **No manual wiki maintenance** — Claude reads raw material and updates structured articles
- **No hunting for files** — Claude queries the knowledge base semantically in every session

The result: a knowledge base that grows with every document you add, and that Claude draws from without being pointed to specific files.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     INPUT LAYER                         │
│                                                         │
│  Drop any file into your drop zone                      │
│  (local folder, OneDrive, Dropbox — your choice)        │
│                                                         │
│  Supported: PDF, DOCX, PPTX, XLSX, HTML, TXT, CSV, MD  │
└─────────────────────┬───────────────────────────────────┘
                      │ file appears (fswatch event)
                      ▼
┌─────────────────────────────────────────────────────────┐
│                  CONVERSION LAYER                       │
│                                                         │
│  watcher.sh — runs 24/7 as a launchd service            │
│                                                         │
│  1. Validates file (type, size, no symlinks)            │
│  2. Converts to Markdown via markitdown (Microsoft)     │
│  3. Saves .md to knowledge-base/raw/                    │
│  4. Moves original to archive folder                    │
└─────────────────────┬───────────────────────────────────┘
                      │ .md file in raw/
                      ▼
┌─────────────────────────────────────────────────────────┐
│                  CURATION LAYER                         │
│                                                         │
│  kb-compile — Claude Code skill                         │
│                                                         │
│  Claude reads raw/ files and:                           │
│  - Routes each to the right discipline folder           │
│  - Merges new info into existing articles               │
│  - Updates the master index                             │
│  - Flags gaps and contradictions                        │
└─────────────────────┬───────────────────────────────────┘
                      │ structured .md articles
                      ▼
┌─────────────────────────────────────────────────────────┐
│                   SEARCH LAYER                          │
│                                                         │
│  QMD (@tobilu/qmd) — local semantic search MCP server   │
│                                                         │
│  Indexes all articles. Claude queries the KB            │
│  automatically in every session — no manual lookup.     │
│                                                         │
│  - BM25 keyword search                                  │
│  - Vector / semantic search                             │
│  - HyDE (hypothetical document embeddings)             │
│                                                         │
│  No data leaves your machine.                           │
└─────────────────────────────────────────────────────────┘
```

---

## Components

| Component | What it is | Role |
|-----------|-----------|------|
| [`pipeline/watcher.sh`](pipeline/watcher.sh) | zsh script | Watches drop folder, converts files, archives originals |
| [`pipeline/*.plist`](pipeline/) | launchd config | Keeps watcher running 24/7, restarts on crash |
| [markitdown](https://github.com/microsoft/markitdown) | Microsoft OSS tool | Converts PDF/DOCX/PPTX/XLSX/HTML → Markdown |
| [fswatch](https://github.com/emcrisostomo/fswatch) | macOS file watcher | Fires events when new files appear |
| [`skills/kb-compile`](skills/kb-compile/SKILL.md) | Claude Code skill | Reads raw/, writes structured wiki articles |
| [`skills/kb-healthcheck`](skills/kb-healthcheck/SKILL.md) | Claude Code skill | Audits wiki for gaps, stale data, orphans |
| [@tobilu/qmd](https://github.com/toblu/qmd) | Local MCP server | Indexes markdown, exposes semantic search to Claude |

---

## Reference folder layout

```
drop-zone/          ← you put files here (any folder or cloud sync)
archive/            ← originals moved here after conversion

knowledge-base/
├── raw/            ← converted .md files land here
│   ├── articles/   ← web clips, industry articles
│   ├── competitors/← competitor intelligence
│   ├── clients/    ← client notes, meeting summaries
│   ├── industry/   ← vertical-specific research
│   ├── research/   ← papers, external reports
│   └── _index.md   ← log of pending / compiled files
│
├── [discipline-1]/ ← curated wiki articles (you define these)
├── [discipline-2]/
├── [discipline-3]/
├── references/     ← source PDFs and reference files
└── _index.md       ← master wiki index
```

The knowledge base folder should live somewhere that syncs across devices — Obsidian vault (iCloud), Dropbox, or similar.

---

## Day-to-day usage

**Adding knowledge:**
1. Drop any supported file into your drop zone
2. It converts to Markdown automatically within seconds
3. Open Claude Code, run `/kb-compile`
4. Done — the article is in the wiki and searchable

**Querying the knowledge base:**
- Ask Claude anything in any session: "what do we know about X?"
- Claude searches QMD automatically and grounds its response in your KB

**Maintenance:**
- Run `/kb-healthcheck` periodically to find gaps, stale entries, and unprocessed files

---

## Setup overview

Full guides for each component are in `docs/`:

| Step | Guide |
|------|-------|
| 1. Understand the philosophy | [docs/philosophy.md](docs/philosophy.md) |
| 2. Install the conversion pipeline | [docs/pipeline-setup.md](docs/pipeline-setup.md) |
| 3. Install and configure QMD | [docs/qmd-setup.md](docs/qmd-setup.md) |
| 4. Install the Claude Code skills | [docs/skills-setup.md](docs/skills-setup.md) |
| 5. Troubleshoot | [docs/troubleshooting.md](docs/troubleshooting.md) |

Quick start if you want to jump straight in:

```bash
# 1. Install dependencies
brew install fswatch
curl -LsSf https://astral.sh/uv/install.sh | sh   # for uvx / markitdown
curl -fsSL https://bun.sh/install | bash            # for bun / qmd

# 2. Install QMD
bun install -g @tobilu/qmd

# 3. Set up the watcher
mkdir -p ~/.local/bin ~/.local/logs
cp pipeline/watcher.sh ~/.local/bin/knowhow-watcher.sh
chmod +x ~/.local/bin/knowhow-watcher.sh
# Edit WATCH_DIR, OUTPUT_DIR, ARCHIVE_DIR at the top of the script

# 4. Install the launchd service
cp pipeline/com.odcus.knowhow-watcher.plist ~/Library/LaunchAgents/
sed -i '' 's/YOUR_USERNAME/'"$(whoami)"'/g' ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist
launchctl load ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist

# 5. Add QMD to Claude Code MCP config (~/.mcp.json)
# See docs/qmd-setup.md

# 6. Install the skills
# See docs/skills-setup.md
```

---

## Philosophy

Built on two ideas — one about how knowledge should be maintained, one about how it should be accessed.

**Karpathy-style KB** — Andrej Karpathy's approach: the AI is the librarian, not you. You collect raw material. The AI reads, structures, and maintains the wiki. You never edit articles directly. The system grows without maintenance overhead.

**QMD by Tobi Lütke** — Shopify's CEO built `@tobilu/qmd`: documents should be *queryable*, not just *searchable*. QMD makes your markdown knowledge base queryable with three modes (BM25, vector, HyDE), accessible to Claude in real time through the MCP protocol.

Full details: [docs/philosophy.md](docs/philosophy.md)

---

## License

MIT — see [LICENSE](LICENSE)
