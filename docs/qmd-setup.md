# QMD Setup

QMD is a local semantic search engine that runs as an MCP server. It indexes your markdown files and exposes search tools that Claude can call automatically in any session.

## What it does

- Indexes all `.md` files in a configured collection (e.g. `knowhow/`)
- Provides three search modes: keyword (BM25), semantic (vector), and hypothetical (HyDE)
- Runs locally — no data leaves your machine
- Re-indexes automatically when the knowledge base is updated

## Installation

QMD runs as an MCP server configured in `~/.mcp.json` or `~/.claude/settings.json`.

### 1. Install QMD

```bash
# Via npm (check qmd docs for current install method)
npm install -g @qmd/server
```

### 2. Configure the MCP server

Add to `~/.mcp.json`:

```json
{
  "mcpServers": {
    "qmd": {
      "command": "qmd",
      "args": ["serve"],
      "env": {
        "QMD_COLLECTIONS": "odcus-knowhow:/path/to/knowhow"
      }
    }
  }
}
```

Replace `/path/to/knowhow` with the absolute path to your knowledge base folder.

### 3. Restart Claude Code

After adding the server, restart Claude Code. QMD will index your collection on first run.

## Search modes

| Mode | Type | When to use |
|------|------|-------------|
| `lex` | BM25 keyword | Exact terms, fast lookup |
| `vec` | Vector/semantic | Meaning-based, finds related concepts |
| `hyde` | Hypothetical | Best results, slower — write what the answer looks like |

### Example queries in Claude Code

```
# Keyword search
Search the knowhow collection for "Zero Trust"

# Semantic search
What do we know about cloud cost optimization for Swiss SMEs?

# Combined (best results)
Find everything relevant to NIS2 compliance for manufacturing clients
```

## Re-indexing

QMD re-indexes automatically when files change in the watched folder. After running `/odcus-kb-compile`, the new articles are available for search in the same session.

## Collection structure

The `odcus-knowhow` collection maps to `02-operations/knowhow/` with these discipline subfolders:

| Folder | Topics |
|--------|--------|
| `cyber/` | Security, Zero Trust, identity, MFA |
| `compliance/` | NIS2, DSG, GDPR, ISO 27001, FINMA |
| `finops/` | Cloud costs, M365, SaaS waste |
| `sourcing/` | Vendor selection, procurement, RFP |
| `modernization/` | Legacy systems, cloud migration |
| `ai/` | AI adoption, shadow AI, governance |
| `managed/` | Managed services, SLA, outsourcing |

Each article is a single markdown file per topic. Articles are never duplicated — new source material updates existing articles.
