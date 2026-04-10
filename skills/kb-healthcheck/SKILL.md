---
name: kb-healthcheck
description: Run a health check on the knowledge base wiki. Use when the user says "kb health check," "check the wiki," "lint the knowledge base," or "find gaps." Scans knowledge-base/ for inconsistencies, orphaned raw files, stale data, and missing connections. Outputs a health report with prioritized findings.
metadata:
  version: 1.0.0
---

# Knowledge Base — Health Check

You audit the knowledge base and produce a structured health report.

## Setup

Update the folder references in this file to match your knowledge base location before use.

---

## Scope

```
knowledge-base/
  raw/                   ← intake (check for orphans)
    _index.md            ← processed/unprocessed log
  [discipline-1]/        ← wiki articles
  [discipline-2]/
  ...
  _index.md              ← master wiki index
```

---

## What You Check

### 1. Orphaned raw files
- Scan all subdirectories of `raw/`
- Cross-reference with `raw/_index.md` (Pending + Compiled tables)
- Any `.md` or `.txt` file not in either table → **orphaned** (add to report)

### 2. Inconsistencies across articles
- Read all `.md` files in the discipline folders
- Flag contradictions: facts in one article that conflict with another
- Flag duplication: same information in two places with different phrasing
- Flag stale data: claims with a specific date older than 12 months that haven't been marked as reviewed

### 3. Missing connections
- Concepts mentioned in one article with no link to a relevant sibling article
- Topics that appear in `raw/` but have no corresponding article
- Discipline folders that are empty despite obvious topic candidates

### 4. Article quality scan
- Articles with no Sources section → traceability gap
- Articles shorter than 150 words → potentially underdeveloped
- Articles missing standard header fields (Last Updated, Discipline, Depth)
- Vague, uncited claims ("many companies," "most businesses") → need grounding

### 5. Index coverage
- Read `knowledge-base/_index.md`
- Any `.md` files in discipline folders NOT referenced in the index → missing entry
- Any index entries pointing to files that don't exist → broken links
- Verify entry counts match actual file counts

### 6. New article candidates
- Suggest 3-5 new articles worth creating based on:
  - Empty discipline folders
  - Topics that appear in raw/ but aren't compiled
  - Gaps relative to your domain

---

## Output Format

Write the health report to `knowledge-base/raw/_health-report.md` and summarize findings in the terminal.

```markdown
# Knowledge Base Health Report — YYYY-MM-DD

## Summary

- Wiki articles: [count] across [discipline count] disciplines
- Raw files: [count] ([pending] pending, [compiled] compiled, [orphaned] orphaned)
- Issues found: [count] ([critical] critical, [minor] minor)

---

## Critical Issues

### Orphaned raw files ([count])
| File | Action |
|------|--------|
| `raw/articles/file.md` | Add to _index.md Pending |

### Broken index links ([count])
| Entry | Issue |
|-------|-------|
| `discipline/topic.md` | File does not exist |

---

## Inconsistencies ([count])

| Files | Issue | Recommendation |
|-------|-------|----------------|
| `a.md` vs `b.md` | Conflicting claim | Verify and align |

---

## Stale Data ([count])

| File | Claim | Date | Action |
|------|-------|------|--------|
| `discipline/topic.md` | Statistic cited | 2023 | Re-verify |

---

## Minor Issues

### Articles without Sources sections
[List files]

### Underdeveloped articles (< 150 words)
[List files]

---

## Empty Disciplines

| Discipline | Folder | Suggested First Article |
|-----------|--------|------------------------|
| [Name] | `folder/` | [Topic] |

---

## New Article Candidates

1. **[Title]** — [Why this gap matters]
2. **[Title]** — [Why this gap matters]
3. **[Title]** — [Why this gap matters]

---

## Suggested Next Actions

1. [Most impactful fix]
2. [Second most impactful]
3. [Third]
```

---

## After Writing the Report

1. Summarize the top 3 critical issues directly in the terminal
2. Ask the user if they want to fix any issues now or run kb-compile on orphaned files
3. Do not auto-fix inconsistencies — flag them, let the user decide

---

## Gotchas

- **Don't auto-fix inconsistencies** — flag them, let the user decide
- **Don't generate verbose reports** — the report should be scannable in 2 minutes
- **Don't invent issues** — only flag what you actually find in the files
- **Flag, don't fix** — health check is diagnostic only
