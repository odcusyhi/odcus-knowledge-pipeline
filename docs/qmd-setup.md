# QMD Setup

QMD (Query Markdown Documents) is a local MCP server that indexes your markdown knowledge base and gives Claude three search modes — keyword, semantic, and hypothetical — to query it in any session. No data leaves your machine.

---

## What it does

When Claude is working on a task and needs to check the knowledge base, it calls QMD tools automatically. You don't need to point Claude at specific files or tell it what to search for — it queries the collection based on what's relevant to the current task.

Example: you ask Claude to prepare a client briefing on NIS2. Without QMD, Claude works from its training data. With QMD, it first searches the `odcus-knowhow` collection, finds your curated articles on NIS2, ISO 27001, and Swiss DSG requirements, and incorporates that knowledge into the briefing.

The difference is the difference between generic and specific.

---

## Prerequisites

- Claude Code (CLI or desktop)
- A folder of markdown files to index

---

## Installation

### Step 1 — Install QMD

QMD runs as a standalone process managed by Claude Code's MCP layer. Install it via npm:

```bash
npm install -g @qmd/server
```

Verify the install:

```bash
qmd --version
```

### Step 2 — Configure as an MCP server

QMD needs to be registered in your Claude Code MCP configuration. Add it to `~/.mcp.json` (global, available in all projects) or to your project's `.mcp.json`:

```json
{
  "mcpServers": {
    "qmd": {
      "command": "qmd",
      "args": ["serve"],
      "env": {
        "QMD_COLLECTIONS": "odcus-knowhow:/absolute/path/to/knowhow"
      }
    }
  }
}
```

Replace `/absolute/path/to/knowhow` with the full path to your `knowhow/` folder. On macOS with iCloud:

```
/Users/yourname/Library/Mobile Documents/iCloud~md~obsidian/Documents/ODCUS/02-operations/knowhow
```

**Multiple collections** are supported — separate them with a comma:

```json
"QMD_COLLECTIONS": "odcus-knowhow:/path/to/knowhow,other-collection:/path/to/other"
```

### Step 3 — Restart Claude Code

MCP servers load at startup. Restart Claude Code after editing the config. QMD will index your collection on first run — this takes a few seconds for a small knowledge base, longer for hundreds of articles.

### Step 4 — Verify

In a Claude Code session, ask:

```
Search the odcus-knowhow collection for "Zero Trust"
```

If QMD is running correctly, Claude will return matching passages from your knowledge base.

---

## Search modes

QMD exposes three search modes. Claude chooses the right one based on the query, but you can also request a specific mode explicitly.

### BM25 — keyword search

Best for: exact terms, proper nouns, product names, standards identifiers (NIS2, ISO 27001, FINMA)

```
[lex search] NIS2 directive
```

Fast and deterministic. If the term appears in the knowledge base, BM25 finds it. If it doesn't, BM25 returns nothing — which is itself useful information.

### Vector search — semantic

Best for: concepts, questions, open-ended queries

```
[vec search] cloud cost reduction for SMEs
```

Text is embedded into a vector space. The search finds passages whose *meaning* is close to the query, even if they share no words. "IT spending efficiency" will match articles about FinOps, SaaS rationalization, and license management.

### HyDE — hypothetical document

Best for: complex queries where you need the most relevant passage across the whole collection

```
[hyde search] what are the main compliance gaps we see in Swiss manufacturing clients
```

QMD generates a short hypothetical answer to the query, then uses that hypothetical as the search vector. Because the hypothetical uses the same vocabulary and structure as real knowledge base articles, the semantic match is more precise. Slower than the other modes — use it when accuracy matters more than speed.

### Combined search (recommended)

For best results, combine all three in a single query:

```json
[
  {"type": "lex", "query": "NIS2"},
  {"type": "vec", "query": "regulatory compliance Swiss manufacturers"},
  {"type": "hyde", "query": "what NIS2 means for Swiss SMEs in manufacturing"}
]
```

Claude does this automatically when searching for complex topics.

---

## Collection structure

The `odcus-knowhow` collection is organized by consulting discipline. Each article is one markdown file covering one topic in depth. QMD indexes all of them.

```
knowhow/
├── cyber/
│   ├── zero-trust.md
│   ├── identity-access-management.md
│   └── endpoint-security.md
├── compliance/
│   ├── nis2.md
│   ├── swiss-dsg.md
│   └── iso-27001.md
├── finops/
│   ├── m365-cost-optimization.md
│   └── saas-rationalization.md
├── sourcing/
│   └── vendor-selection-framework.md
├── modernization/
│   └── cloud-migration-patterns.md
├── ai/
│   └── shadow-ai-governance.md
└── managed/
    └── managed-services-sla.md
```

Each file follows the same structure so QMD can chunk and index it consistently:
- H1: article title
- H2: major sections
- H3: subsections
- Bullet lists for facts and criteria
- Short paragraphs, one idea each

---

## Re-indexing

QMD watches its configured collection folder and re-indexes automatically when files change. After running `/odcus-kb-compile` (which writes or updates articles in the discipline folders), the new content is available for search within seconds.

You can also trigger a manual re-index:

```bash
qmd reindex odcus-knowhow
```

---

## Checking index status

```bash
# List collections and document counts
qmd status

# Show what's indexed in a collection
qmd list odcus-knowhow
```

---

## Context window efficiency

QMD returns passages, not full documents. When Claude searches for "Zero Trust", it gets the most relevant 2-3 paragraphs from the most relevant articles — not every word of every article that mentions the term. This keeps the context window lean even as the knowledge base grows.

The knowledge base can contain hundreds of articles. Claude's responses stay grounded in relevant specifics, not diluted by everything the KB contains.
