# Philosophy

This system is built on two ideas — one about how knowledge should be maintained, one about how it should be accessed.

---

## The Karpathy Approach: AI as Librarian

### The problem with traditional PKM

Most knowledge management systems fail for the same reason: they require too much from the person using them.

You read an article. You clip it. You tag it. You file it in a folder with a system you invented six months ago and have since half-forgotten. You mean to write a summary. You don't. Three months later, you can't find it. Six months later, you've forgotten it existed.

The failure mode isn't laziness — it's that the overhead of maintaining the system exceeds the value of the knowledge being stored. So people stop maintaining it, and the system dies.

### The inversion

Andrej Karpathy's approach inverts the responsibility: **the AI maintains the knowledge, not you.**

Your role is reduced to a single step: collect and drop raw material. Everything after that — reading, extracting, structuring, routing, updating, indexing — is done by the AI.

This works because AI is good at exactly the things humans are bad at in knowledge management:
- Reading the same content many times without fatigue
- Routing a document to the right place without deciding where that is
- Merging new information into an existing article without creating a duplicate
- Noticing when two articles contradict each other
- Flagging when a topic hasn't been updated in months

### What changes in practice

**Before:** You read a report → you decide it's important → you try to file it → you forget to → it sits in Downloads

**After:** You get a report → you drop it in a folder → the system converts it, routes it, and updates the wiki → next time Claude is working on something related, it draws on that report automatically

The knowledge base grows every time you drop a file. It never shrinks. It never degrades from neglect — articles stay accurate until new information updates them.

### The rules that make it work

Three constraints keep the system coherent:

1. **Never edit wiki articles directly.** If you edit manually, the AI loses track of what it wrote. On the next compile, it may overwrite your changes or create inconsistencies. All knowledge enters through `raw/`.

2. **Always compile after adding.** The conversion pipeline gets content into `raw/` automatically, but the curation step — routing, merging, indexing — requires a deliberate `/odcus-kb-compile` run. This is intentional: it gives you a moment to review what's been ingested before it's integrated.

3. **Run healthchecks.** The AI doesn't know what it doesn't know. `/odcus-kb-healthcheck` surfaces gaps — topics with no coverage, articles that haven't been updated despite new source material, questions Claude can't answer from the current KB.

---

## Tobi Lütke's QMD: Documents as a Database

### The problem with file search

Traditional file search — whether macOS Spotlight, Windows Search, or grep — finds files that *contain* a keyword. It's good for exact matches and terrible for everything else.

"Find me everything we know about regulatory compliance for Swiss manufacturing clients" is not a search query that file search can answer. It requires understanding that:
- "Swiss manufacturing" implies FINMA, NIS2, and ISO 27001 are relevant
- "Regulatory compliance" connects to your compliance folder but also to entries in `cyber/` and `ai/`
- The most relevant passage might not contain the words "Swiss" or "manufacturing" at all

Tobi Lütke's insight: **your documents should be queryable, not just searchable.** The distinction matters because querying implies intent-awareness — you describe what you're looking for, not the exact words it might contain.

### How QMD implements this

QMD (Query Markdown Documents) is a local search server that indexes your markdown files and exposes three search modes to Claude:

**BM25 (lexical search)**
Classic keyword matching with term frequency weighting. Fast, deterministic, good for exact terms and proper nouns. "NIS2 directive" will find every article that mentions it.

**Vector search (semantic)**
Each chunk of text is embedded as a vector. Queries are embedded the same way. The search finds chunks whose *meaning* is close to the query's meaning — even if they share no words. "How do we help clients reduce IT spend?" will find articles about FinOps, cloud cost optimization, and SaaS rationalization, even if those exact words don't appear together anywhere.

**HyDE (Hypothetical Document Embeddings)**
Before searching, the model generates a short hypothetical answer to the query. That hypothetical answer is then used as the search vector. This works because the hypothetical answer uses the same vocabulary and framing as real answers in the knowledge base, making the semantic match more precise. Slower, but the best results for complex queries.

In practice, Claude combines all three depending on what's being asked.

### Why markdown specifically

The choice of markdown as the storage format is deliberate:

- **Human-readable** — you can open any article in Obsidian, VSCode, or a plain text editor and read it without tooling
- **Structured enough to chunk** — headers, lists, and code blocks give QMD natural boundaries for splitting articles into indexable segments
- **No proprietary lock-in** — plain files, no database, no application dependency
- **Syncs anywhere** — iCloud, Dropbox, Git, OneDrive — markdown files travel without friction
- **Claude-native** — Claude is trained on vast amounts of markdown; the format maps naturally to how it reasons about document structure

Every wiki article is one `.md` file per topic. QMD indexes them as a collection. Claude queries the collection. The knowledge flows into Claude's responses without you doing anything.

### What this enables

In any Claude Code session, Claude can answer questions like:

- "What have we seen in client engagements around Zero Trust adoption blockers?"
- "Summarize everything we know about NIS2 requirements for Swiss SMEs"
- "What competitors are active in the FinOps space and what are their weaknesses?"
- "What does our KB say about shadow AI risks in professional services firms?"

Without QMD, answering these questions requires you to know which files exist, find them, open them, and point Claude at them. With QMD, Claude handles the retrieval automatically.

---

## How the two ideas connect

Karpathy's approach solves the *supply* problem: how do you build a knowledge base without it becoming a maintenance burden?

QMD solves the *access* problem: how do you actually use a knowledge base once it exists?

Together they form a closed loop:

```
You drop a file
    → converted automatically
    → curated by AI into structured articles
    → indexed by QMD
    → available to Claude in every session
    → Claude produces better work
    → you learn what knowledge gaps exist
    → you drop more files
```

The system gets more useful the more you use it. That's the compounding effect traditional PKM promises but rarely delivers.
