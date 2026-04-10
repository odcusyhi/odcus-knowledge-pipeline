# ODCUS Knowledge Pipeline

An AI-maintained knowledge base with automatic document ingestion, conversion, and semantic search — built on three ideas:

1. **Karpathy-style KB** — you feed raw material, AI maintains the knowledge. You never edit the wiki directly.
2. **QMD semantic search** — a local search engine indexes all markdown so Claude can query the KB automatically in any session.
3. **Automated ingestion pipeline** — drop any file into a OneDrive folder, it gets converted to Markdown and integrated automatically.

---

## How it fits together

```
OneDrive (Knowledge Process)
        │
        │  drop PDF / DOCX / PPTX / XLSX
        ▼
[fswatch + markitdown]        ← runs locally, 24/7
        │
        │  converts to .md
        ▼
knowhow/raw/                  ← Obsidian vault (iCloud)
        │
        │  /odcus-kb-compile
        ▼
knowhow/{discipline}/         ← structured wiki articles
        │
        │  qmd index
        ▼
Claude Code sessions          ← semantic search via MCP
```

---

## Sections

- [Philosophy](docs/philosophy.md) — Karpathy-style KB + Tobi Lütke's QMD approach
- [QMD Setup](docs/qmd-setup.md) — local semantic search over markdown
- [Pipeline Setup](docs/pipeline-setup.md) — automated file ingestion
- [`pipeline/`](pipeline/) — the watcher script and launchd config
