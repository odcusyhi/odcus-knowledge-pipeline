# Skills Setup

The two Claude Code skills — `kb-compile` and `kb-healthcheck` — are the curation layer of the pipeline. They're how Claude reads raw intake files and writes structured wiki articles.

Skills are prompt files that Claude Code loads when you invoke a slash command. They live in `~/.claude/skills/` and are triggered by running `/skill-name` in any session.

---

## Installing the skills

### Step 1 — Copy the skill files

```bash
# Create skill directories
mkdir -p ~/.claude/skills/kb-compile
mkdir -p ~/.claude/skills/kb-healthcheck

# Copy from this repo
cp skills/kb-compile/SKILL.md ~/.claude/skills/kb-compile/SKILL.md
cp skills/kb-healthcheck/SKILL.md ~/.claude/skills/kb-healthcheck/SKILL.md
```

### Step 2 — Update the paths

Both skills reference `knowledge-base/raw/` and `knowledge-base/` as generic placeholders. Update them to match your actual folder structure.

Open `~/.claude/skills/kb-compile/SKILL.md` and update:

1. The folder structure diagram to reflect your actual paths
2. The discipline routing table to match your knowledge domains
3. The QMD re-index commands if your binary path differs

Open `~/.claude/skills/kb-healthcheck/SKILL.md` and update:

1. The folder structure diagram to match your paths

### Step 3 — Verify

Restart Claude Code. In any session, run:

```
/kb-compile
```

Claude should begin scanning your `raw/` folder for unprocessed files.

---

## Customising the discipline structure

The routing table in `kb-compile` defines how Claude categorises raw content. The default template has placeholder disciplines — replace them with your actual knowledge domains.

**Example for a legal firm:**

```markdown
| Content type | Folder |
|-------------|--------|
| Contract law, litigation, case studies | `contracts/` |
| Regulatory updates, compliance | `regulatory/` |
| Client intake, meeting notes | `clients/` |
| Market research, competitor analysis | `market/` |
```

**Example for a software team:**

```markdown
| Content type | Folder |
|-------------|--------|
| Architecture decisions, system design | `architecture/` |
| Security vulnerabilities, patches | `security/` |
| API documentation, integration notes | `integrations/` |
| Incident reports, post-mortems | `incidents/` |
```

The folders just need to exist in your knowledge base. Create them before running compile:

```bash
mkdir -p /path/to/knowledge-base/{discipline-1,discipline-2,discipline-3}
```

---

## How the compile skill works

When you run `/kb-compile`:

1. Claude reads `raw/_index.md` to find pending files
2. Scans raw subdirectories for any untracked files
3. For each pending file:
   - Reads the file
   - Determines the right discipline folder
   - Updates an existing article or creates a new one
   - Logs the file as compiled in `raw/_index.md`
4. Updates the master `_index.md`
5. Runs `qmd update && qmd embed` to re-index for search
6. Reports what was processed

You never edit wiki articles directly. All knowledge enters through `raw/` and is curated by Claude.

---

## How the healthcheck skill works

When you run `/kb-healthcheck`:

1. Claude scans `raw/` for orphaned files (not in the index)
2. Reads all discipline articles and checks for:
   - Contradictions between articles
   - Duplicate content
   - Stale statistics (older than 12 months)
   - Articles missing sources sections or standard headers
   - Empty discipline folders
3. Checks `_index.md` for broken links and missing entries
4. Suggests new articles based on gaps
5. Writes a health report to `raw/_health-report.md`
6. Summarises the top issues in the terminal

Run this periodically — monthly works well for an active knowledge base.

---

## Naming the skills differently

If you want to name the slash commands something other than `/kb-compile` and `/kb-healthcheck`, rename the skill directories:

```bash
mv ~/.claude/skills/kb-compile ~/.claude/skills/my-compile-name
mv ~/.claude/skills/kb-healthcheck ~/.claude/skills/my-healthcheck-name
```

The directory name becomes the slash command name.

---

## Skill file format reference

Each skill is a single `SKILL.md` file with YAML frontmatter:

```markdown
---
name: skill-name
description: When to trigger this skill. Claude Code uses this to match user intent.
metadata:
  version: 1.0.0
---

# Skill instructions

[Everything below the frontmatter is the prompt Claude follows when the skill runs]
```

The `description` field is important — it's how Claude Code decides whether to invoke the skill based on what you type. Keep it specific to the trigger phrases you'll actually use.
