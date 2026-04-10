# QMD Setup

QMD (Query Markdown Documents) is a local MCP server that indexes your markdown knowledge base and gives Claude three search modes — keyword, semantic, and hypothetical — to query it in any session. No data leaves your machine.

---

## What it does

When Claude is working on a task and needs to check the knowledge base, it calls QMD tools automatically. You don't need to point Claude at specific files or tell it what to search for — it queries the collection based on what's relevant to the current task.

Example: you ask Claude to prepare a client briefing on NIS2. Without QMD, Claude works from its training data. With QMD, it first searches the knowledge base, finds your curated articles on NIS2, ISO 27001, and relevant regulatory requirements, and incorporates that specific knowledge into the briefing.

The difference is the difference between generic and specific.

---

## Prerequisites

- Claude Code (CLI or desktop app)
- A folder of markdown files to index

---

## Installation

### Step 1 — Install QMD

QMD runs as a standalone process managed by Claude Code's MCP layer. Install via npm:

```bash
npm install -g @qmd/server
```

Verify:

```bash
qmd --version
```

### Step 2 — Configure as an MCP server

Add QMD to your Claude Code MCP config. Use `~/.mcp.json` for global access across all projects, or your project's `.mcp.json` for project-scoped access:

```json
{
  "mcpServers": {
    "qmd": {
      "command": "qmd",
      "args": ["serve"],
      "env": {
        "QMD_COLLECTIONS": "my-knowhow:/absolute/path/to/knowledge-base"
      }
    }
  }
}
```

Replace `/absolute/path/to/knowledge-base` with the full path to your knowledge base folder.

**Examples:**

iCloud / Obsidian vault:
```
/Users/yourname/Library/Mobile Documents/iCloud~md~obsidian/Documents/Vault/knowledge-base
```

Local folder:
```
/Users/yourname/Documents/knowledge-base
```

**Multiple collections** — separate with a comma:
```json
"QMD_COLLECTIONS": "knowhow:/path/to/kb,research:/path/to/research"
```

### Step 3 — Restart Claude Code

MCP servers load at startup. Restart Claude Code after editing the config. QMD indexes your collection on first run.

### Step 4 — Verify

In a Claude Code session:

```
Search the knowhow collection for "Zero Trust"
```

If QMD is running, Claude returns matching passages from your knowledge base.

---

## Search modes

QMD exposes three search modes. Claude selects the appropriate one automatically, but you can also request a specific mode.

### BM25 — keyword search

Best for: exact terms, proper nouns, standards identifiers (NIS2, ISO 27001, GDPR)

Fast and deterministic. If the term is in the knowledge base, BM25 finds it.

### Vector search — semantic

Best for: concepts, questions, open-ended queries

Text is embedded into vector space. Finds passages whose *meaning* is close to the query — even when no exact words match. "IT cost reduction" will match articles about cloud FinOps, SaaS rationalization, and license management.

### HyDE — hypothetical document

Best for: complex queries where precision matters most

QMD generates a short hypothetical answer to the query, then uses that as the search vector. Because the hypothetical mirrors the style of real knowledge base articles, the semantic match is more precise. Slower than the other modes.

### Combined search (recommended)

For best results, combine all three:

```json
[
  {"type": "lex", "query": "NIS2"},
  {"type": "vec", "query": "regulatory compliance Swiss manufacturers"},
  {"type": "hyde", "query": "what NIS2 means for SMEs in manufacturing"}
]
```

Claude does this automatically for complex topics.

---

## Knowledge base structure

Each article is one markdown file covering one topic. QMD indexes all of them and returns passage-level results — not whole documents — which keeps Claude's context window lean even as the knowledge base grows.

Recommended structure:

```
knowledge-base/
├── cyber/            ← cybersecurity topics
├── compliance/       ← regulatory & compliance topics
├── finops/           ← cloud cost & SaaS management
├── sourcing/         ← vendor selection & procurement
├── modernization/    ← cloud migration & legacy systems
├── ai/               ← AI adoption & governance
├── managed/          ← managed services & SLAs
├── raw/              ← intake: converted files land here
└── _index.md         ← master index
```

Adapt discipline folders to your domain. The structure itself doesn't affect how QMD indexes — it indexes all `.md` files recursively.

---

## Re-indexing

QMD watches its collection folder and re-indexes automatically when files change. After running `/odcus-kb-compile`, new articles are available for search within seconds.

Manual re-index if needed:

```bash
qmd reindex my-knowhow
```

---

## Checking index status

```bash
qmd status           # list collections and document counts
qmd list my-knowhow  # show what's indexed
```
