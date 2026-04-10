# QMD Setup

QMD (`@tobilu/qmd`) is a local semantic search tool and MCP server built by Tobi Lütke (CEO of Shopify). It indexes your markdown knowledge base and exposes three search modes — keyword, semantic, and hypothetical — that Claude can call automatically in any session.

Everything runs locally. No data leaves your machine.

---

## What it does

When Claude works on a task and needs to check the knowledge base, it calls QMD tools automatically through the MCP protocol. You don't point Claude at specific files — it queries the collection based on what's relevant.

Example: you ask Claude to summarize what you know about a topic. Without QMD, it works from training data alone. With QMD, it first searches your knowledge base, finds your curated articles, and incorporates that specific knowledge into the response.

---

## Prerequisites

- [Bun](https://bun.sh) — the JavaScript runtime QMD runs on
- [Claude Code](https://claude.ai/code) — CLI or desktop

Install Bun if you don't have it:

```bash
curl -fsSL https://bun.sh/install | bash
```

---

## Installation

### Step 1 — Install QMD

```bash
bun install -g @tobilu/qmd
```

Verify:

```bash
qmd --version
```

### Step 2 — Add your knowledge base as a collection

```bash
qmd collection add my-knowhow /absolute/path/to/knowledge-base
```

Replace `my-knowhow` with whatever name you want and the path with your actual knowledge base folder. The name is what you'll use in queries and MCP config.

Verify the collection was added:

```bash
qmd collection list
```

### Step 3 — Build the initial index

```bash
qmd update
qmd embed
```

`qmd update` indexes file content (BM25). `qmd embed` generates vector embeddings for semantic search. Both are needed for full functionality.

This takes a few seconds for small knowledge bases and longer for hundreds of articles.

### Step 4 — Configure as an MCP server

Add QMD to your Claude Code MCP configuration. Edit `~/.mcp.json` (global, all projects) or your project's `.mcp.json`:

```json
{
  "mcpServers": {
    "qmd": {
      "command": "qmd",
      "args": ["mcp"]
    }
  }
}
```

If `qmd` isn't in your `PATH`, use the full binary path. Find it with:

```bash
which qmd
```

Then use that path in the config:

```json
{
  "mcpServers": {
    "qmd": {
      "command": "/Users/yourname/.bun/bin/qmd",
      "args": ["mcp"]
    }
  }
}
```

### Step 5 — Restart Claude Code

MCP servers load at startup. Restart Claude Code after editing the config.

### Step 6 — Verify

In a Claude Code session:

```
Search the my-knowhow collection for "your topic"
```

Claude should return matching passages from your knowledge base.

---

## Search modes

QMD exposes three search modes. Claude selects the appropriate one, but you can also request a specific mode explicitly.

### BM25 — keyword search

Best for: exact terms, proper nouns, identifiers, standards names

Fast and deterministic. If the term is in the knowledge base, BM25 finds it.

```
Search my-knowhow for "GDPR Article 17"
```

### Vector search — semantic

Best for: concepts, open-ended questions, anything where exact words don't matter

Embeds text as vectors. Finds passages whose *meaning* is close to the query, even with no word overlap. "How do we reduce software costs?" will match articles about SaaS rationalization, license management, and cloud FinOps.

```
What does the knowledge base say about reducing software spend?
```

### HyDE — hypothetical document embeddings

Best for: complex queries where precision matters most

QMD generates a short hypothetical answer, then uses that as the search vector. Because the hypothetical mirrors the vocabulary of real knowledge base articles, matches are more precise. Slower than the other modes.

### Combined query (default for complex topics)

QMD's `query` command combines all three automatically:

```bash
qmd query "your question here"
```

Claude does this automatically when the query is complex.

---

## Re-indexing after compile

After running `/kb-compile` (which writes new articles to your discipline folders), update the QMD index:

```bash
qmd update
qmd embed
```

Or run both in sequence:

```bash
qmd update && qmd embed
```

The compile skill does this automatically as its final step — so in normal usage you don't need to run it manually.

---

## Useful commands

```bash
# Check index health
qmd status

# List indexed files in a collection
qmd collection show my-knowhow

# Search from the terminal
qmd query "your question"
qmd search "exact keyword"    # BM25 only
qmd vsearch "your question"   # vector only

# Fetch a specific file
qmd get knowledge-base/cyber/zero-trust.md

# Re-index
qmd update        # re-index content
qmd embed         # regenerate vector embeddings
qmd embed -f      # force regenerate all embeddings

# Clean up caches
qmd cleanup
```

---

## Multiple collections

You can index multiple folders as separate collections:

```bash
qmd collection add work-kb /path/to/work-knowledge
qmd collection add personal-kb /path/to/personal-notes
```

Each collection is searchable independently. Useful if you want to keep different knowledge bases separated while still querying them from Claude Code.

---

## Notes

- QMD stores its index locally in `~/.qmd/` — no cloud sync required
- Vector embeddings are generated locally using a bundled model
- The MCP server starts on demand when Claude Code calls a QMD tool — it does not run as a persistent background process
