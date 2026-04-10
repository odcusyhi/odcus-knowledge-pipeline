# Philosophy

## The Karpathy Approach: AI as Knowledge Curator

Traditional personal knowledge management (PKM) puts the maintenance burden on you. You clip articles, tag them, file them, and try to connect them later. The system degrades the moment you stop feeding it.

Andrej Karpathy's approach inverts this: **the AI maintains the knowledge, not you.** You are a source collector. The AI is the librarian.

In practice:
- You drop raw material (articles, PDFs, meeting notes, research) into an intake folder
- An AI processes each piece: extracts what matters, routes it to the right place, updates existing articles rather than creating duplicates, and flags gaps
- The knowledge base grows coherently without you ever manually editing a wiki page

The result is a system that gets more useful as you feed it — and degrades gracefully if you stop (articles stay, they just don't update).

### What this means in practice

**You do:**
- Drop files into the intake folder
- Run `/odcus-kb-compile` to trigger processing
- Occasionally run `/odcus-kb-healthcheck` to find gaps

**You never:**
- Edit wiki articles directly
- Manually tag or categorize
- Worry about where something goes

**The AI does:**
- Routes content to the right discipline folder
- Merges new information into existing articles
- Updates indexes and cross-references
- Flags stale or contradictory information

---

## Tobi Lütke's QMD: Query Your Docs Like a Database

The second idea comes from how Shopify's CEO thinks about AI-augmented work: **your documents should be queryable, not just searchable.**

Traditional file search finds files that contain a keyword. QMD (Query Markdown Documents) finds the passage most relevant to your question — across all documents — using a combination of:

- **BM25 (lexical)** — exact keyword matching, fast
- **Vector search (semantic)** — finds meaning, not just words
- **HyDE (hypothetical document)** — generates what the answer might look like, then finds the closest real match

In a Claude Code session, this means Claude can answer "what do we know about Zero Trust for manufacturing clients?" by searching the knowledge base automatically — without you pointing it to a file.

### Why markdown

Markdown sits at the intersection of human-readable and machine-queryable. It has enough structure (headers, lists, code blocks) for chunking and indexing, but no proprietary format that breaks tooling. Every article in the knowledge base is a plain `.md` file — readable in Obsidian, editable in any text editor, indexable by QMD.

---

## How the two ideas connect

Karpathy's approach gives you a knowledge base that grows without manual effort.
QMD gives Claude the ability to use that knowledge base in real time.

Together: you feed the system, the system feeds Claude, Claude feeds your work.
