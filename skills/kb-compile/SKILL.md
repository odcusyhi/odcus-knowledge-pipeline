---
name: kb-compile
description: Compile new raw source documents into the knowledge base wiki. Use when the user says "compile the knowledge base," "process raw files," "update the wiki," or "kb compile." Reads new files from knowledge-base/raw/, categorizes them by discipline, and updates or creates articles in the appropriate discipline folder.
metadata:
  version: 1.0.0
---

# Knowledge Base — Compile

You maintain a knowledge base wiki by processing raw source documents and compiling their insights into structured discipline folders.

## Setup

Before using this skill, update the two path references in this file to match your knowledge base location:

- `knowledge-base/raw/` → your raw intake folder
- `knowledge-base/` → your wiki root

Also update the discipline routing table below to match your own topic areas.

---

## The System

```
knowledge-base/
  raw/                    ← source documents (intake here)
    articles/             ← web clips, industry articles
    competitors/          ← competitor intelligence
    clients/              ← client notes, meeting summaries
    industry/             ← vertical-specific research
    research/             ← papers, external reports
    _index.md             ← log of all raw items (pending / compiled)

  [discipline-1]/         ← compiled wiki articles
  [discipline-2]/
  [discipline-3]/
  ...
  references/             ← source PDFs and external reference files
  _index.md               ← master wiki index
```

You read raw documents, extract what matters, route content to the right discipline folder, and write structured knowledge articles. You never modify raw files after processing — only update `raw/_index.md` to log them as compiled.

---

## Discipline Routing Guide

Adapt this table to your own knowledge domains:

| Content type | Folder |
|-------------|--------|
| [Your topic 1] | `discipline-1/` |
| [Your topic 2] | `discipline-2/` |
| [Your topic 3] | `discipline-3/` |

If a document clearly spans two disciplines, write the primary insight in the main discipline folder and add a cross-reference note in the other.

---

## Step-by-Step Process

### 1. Read the index

Read `knowledge-base/raw/_index.md`.

- Check the **Pending** table for items that need processing.
- If Pending is empty, scan the raw subdirectories for any `.md` or `.txt` files not listed in either table. Add them to Pending before processing.

### 2. Scan for untracked files

For each subdirectory of `raw/`:
- List all files
- Cross-reference with `raw/_index.md`
- Any file not in Pending or Compiled → add to Pending with today's date

### 3. Process each pending item

For each file in Pending:

**a. Read the file** — understand the full content.

**b. Identify the discipline** — use the routing guide above.

**c. Decide: update existing article or create new one?**
- Does an article already exist for this topic? → update it
- New topic? → create a new article in the correct discipline folder

**d. Write or update the knowledge article:**
- Use the article template below
- Keep it practitioner-level — useful for someone working on the topic
- Never duplicate content already in another article — add a cross-reference instead
- Name files descriptively: `compliance/gdpr-basics.md`, `ai/shadow-ai-risks.md`

**e. Update `knowledge-base/_index.md`:**
- Add new articles to the correct discipline section
- Update entry counts
- Update "Recently Added" table

**f. Move item from Pending to Compiled** in `raw/_index.md`:
- Add the date compiled
- Note which article it mapped to
- Add a 1-line summary of what was extracted

### 4. Re-index for semantic search

After all articles are written, update the QMD search index:

```bash
qmd update
qmd embed
```

### 5. Report

After processing all pending items, output a brief compile report:
- How many files processed
- What was updated vs. created (with paths)
- Any items that were unclear or need human review
- Confirm QMD re-index completed

---

## Article Template

```markdown
# [Topic Title]

**Last Updated:** YYYY-MM-DD
**Discipline:** [Discipline name]
**Depth:** [Overview / Deep]

---

## Summary

[2-4 sentences: what it is, why it matters, key practitioner takeaway]

---

## [Section]

[Content from sources]

---

## Sources

| Raw File | Compiled | Key Contribution |
|----------|----------|-----------------|
| `raw/articles/YYYY-MM-DD_title.md` | YYYY-MM-DD | [1 line] |
```

---

## Gotchas

- **Don't rewrite existing articles from scratch** — append and update sections, preserve existing knowledge
- **Don't invent facts** — only write what's in the source documents; flag uncertainty
- **Don't skip discipline routing** — every article must land in the right folder
- **Don't forget _index.md updates** — both `raw/_index.md` and the master `_index.md` must stay current
- **If a raw file is empty or too short** — log it as compiled but note "no useful content extracted"
