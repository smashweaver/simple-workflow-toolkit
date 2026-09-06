# Product Requirements Document (PRD)
# archive-swt-snapshot — Freeze Current SWT as Reference

> **For AI Coding Agents:** Read this file first. This is the single source of truth for the archival operation. All execution decisions must align with this document. The user has already approved the design through multi-turn dialog — your job is to execute it faithfully and report.

---

## 1. Product Overview

**Name:** archive-swt-snapshot
**Type:** Repository restructuring chore (single chore commit)
**Target User:** The next coding agent picking up the SWT flow-separation refactor
**Core Value:** Freeze the current Simple Workflow Toolkit as an immutable reference snapshot under `./archive/` so that the refactor described in `SWT_FLOW_SEPARATION_IDEATION.md` has stable evidence to work against. Root keeps only the minimum needed to point at the archive and the forward-looking brief.

**Why now:** The current SWT's monolithic `Phase: N` machinery has been assessed as fragile (see `archive/docs/assessments/SWT_COMPLEXITY_SPIRAL_ASSESSMENT.md`, `archive/JAILBREAKS.md`). The brief proposes splitting it into four independent flows (Ideation, Planning, Execution, Commit). Before that refactor begins, the existing code/docs must be moved aside intact — neither deleted (loses reference material) nor left in place (creates coupling that blocks clean rewrite).

---

## 2. Goals & Non-Goals

### Goals (must achieve)

- **G1.** The entire current SWT (skills, docs, scripts, tests, root markdowns, root JSONs, root `.gitignore`) is moved to `./archive/` preserving directory structure exactly.
- **G2.** The four runtime/ephemeral directories (`.digests/`, `.specs/`, `.tasks/`, `graphify-out/`) and `task.ctx` are deleted (they are gitignored session state with no archival value).
- **G3.** `demo/` (empty, gitignored) is deleted.
- **G4.** The ephemeral commit ritual files (`commit.draft`, `commit.task`, `commit.diff`) are deleted if present.
- **G5.** Root is reduced to exactly five entries: `.gitignore` (new stub), `AGENTS.md` (new stub), `README.md` (new stub), `SWT_FLOW_SEPARATION_IDEATION.md` (existing brief, untouched), `archive/` (the snapshot).
- **G6.** A single `chore:` git commit captures the entire move. The commit message documents the bypass and the rationale.
- **G7.** Pre-commit hook bypass (`--no-verify`) is used for this chore commit with documented justification.

### Non-Goals (explicitly out of scope)

- **N1.** Do NOT begin the flow-separation refactor. This is archive-only.
- **N2.** Do NOT create a new task file in `.tasks/`. The archive predates any active task.
- **N3.** Do NOT run the full `swt-commit` Draft-and-Approve ritual for this commit. The ritual will be honored for the *next* commit (refactor work), using the **archived** `archive/skills/swt-commit/` skill per the user's standing instruction.
- **N4.** Do NOT run the test suite. The tests are being archived; they reference the old architecture and won't pass against the new tree.
- **N5.** Do NOT modify anything inside `archive/` after the move. It is a frozen snapshot.
- **N6.** Do NOT create `.agents/`, `.claude/`, `.gemini/`, or `.opencode/` discovery directories. The new stub `.gitignore` keeps them ignored; the refactor will decide discovery strategy.

---

## 3. User Stories

### Primary: Next Coding Agent

- As the next agent, I have a frozen `archive/` snapshot I can `grep`, `cat`, and reference without risk of it changing under me.
- As the next agent, the root `AGENTS.md` stub tells me the methodology is mid-refactor and points me to the brief.
- As the next agent, the root `README.md` stub orients me in three lines.
- As the next agent, the brief `SWT_FLOW_SEPARATION_IDEATION.md` is the only forward-looking artifact at root, so there is no ambiguity about where to start.
- As the next agent, when I need to commit refactor work, I read `archive/skills/swt-commit/SKILL.md` and follow the archived ritual — not invent a new one.

### Secondary: User Reviewing the Archive

- As the user, I can `git checkout` the archive commit and see the entire pre-refactor SWT intact, with `git log -1` showing the snapshot metadata.

---

## 4. Data Model

Not applicable — this is a filesystem operation. The "model" is:

| Source | Destination | Type |
|---|---|---|
| `swt/docs/` | `swt/archive/docs/` | recursive move |
| `swt/scripts/` | `swt/archive/scripts/` | recursive move |
| `swt/skills/` | `swt/archive/skills/` | recursive move |
| `swt/tests/` | `swt/archive/tests/` | recursive move |
| 12 root markdowns + 2 root JSONs + old `.gitignore` + old `README.md` | `swt/archive/` | flat move |
| `swt/.digests/`, `swt/.specs/`, `swt/.tasks/`, `swt/graphify-out/`, `swt/demo/`, `swt/task.ctx`, `swt/commit.*` | (deleted) | recursive delete |

`archive/.gitignore` keeps the exact byte content of the old root `.gitignore` (no rewriting during move).

---

## 5. Execution Plan (sequenced)

### Phase A — Move (preserve, do not modify content)

```bash
cd /home/jason/tools/swt

# A.1 Create archive root
mkdir -p archive

# A.2 Move folders (whole tree, preserving structure)
for d in docs scripts skills tests; do
  [ -d "$d" ] && mv "$d" "archive/$d" && echo "moved: $d"
done

# A.3 Move root files
for f in ARCHITECTURE.md CLAUDE.md CONFIG.md GEMINI.md JAILBREAKS.md LOOPS.md MODERNIZE_AGENT_DISCOVERY_PROMPT.md PRD-swt-preview.md SKILLS.md swt.json swt-skills-audit.json README.md; do
  [ -f "$f" ] && mv "$f" "archive/$f" && echo "moved: $f"
done

# A.4 Archive the old .gitignore
[ -f .gitignore ] && mv .gitignore archive/.gitignore && echo "moved: .gitignore"
```

### Phase B — Delete (ephemeral, gitignored)

```bash
cd /home/jason/tools/swt

for d in .digests .specs .tasks graphify-out demo; do
  [ -d "$d" ] && rm -rf "$d" && echo "deleted: $d"
done

[ -f task.ctx ] && rm -f task.ctx && echo "deleted: task.ctx"
for f in commit.draft commit.task commit.diff; do
  [ -f "$f" ] && rm -f "$f" && echo "deleted: $f"
done
```

### Phase C — Verify

```bash
ls -la /home/jason/tools/swt/
# Expected: .git/ .gitignore AGENTS.md README.md SWT_FLOW_SEPARATION_IDEATION.md archive/

ls /home/jason/tools/swt/archive/
# Expected: ARCHITECTURE.md CLAUDE.md CONFIG.md GEMINI.md JAILBREAKS.md LOOPS.md
#           MODERNIZE_AGENT_DISCOVERY_PROMPT.md PRD-swt-preview.md README.md
#           SKILLS.md swt.json swt-skills-audit.json .gitignore
#           docs/ scripts/ skills/ tests/

git status --short
# Expected: many M/A/D status codes — capture for the commit message
```

**If the root listing is not exactly the five expected entries, STOP and report. Do not proceed.**

### Phase D — Write root stubs (after Phase A & B verified)

Write three new files at the root:

**`/home/jason/tools/swt/.gitignore`:**
```
# Minimal stub — full gitignore lives at archive/.gitignore
# Old harness jailbreak-targeted rules removed; refactor will define new ones.

# Python
__pycache__/
*.pyc
*.pyo
.pytest_cache/

# OS
.DS_Store
Thumbs.db

# Editor
.vscode/
.idea/
*.swp
*.swo

# Env
.env
.env.local
.env.*.local

# Agent discovery (dogfooding)
.agents/
.claude/
.gemini/
.opencode/

# Runtime / cache
.cache/
.tasks/
.specs/
.digests/
graphify-out/

# Commit ritual temp files
commit.diff
commit.draft
commit.task

# Task context pointer
task.ctx
```

**`/home/jason/tools/swt/AGENTS.md`:**
```markdown
# AGENTS.md — Temporary Stub

This repository is mid-refactor. The previous SWT methodology has been
archived to `./archive/AGENTS.md` for reference.

The current forward direction is documented in
`SWT_FLOW_SEPARATION_IDEATION.md`. Work will resume under a new contract
once the refactor task is opened.

Until then, minimal rules for this session:

- Be concise.
- Prefer `./archive/` references over inventing prior context.
- Follow the **archived `swt-commit` ritual** (Draft-and-Approve) for any
  commit. Use `archive/skills/swt-commit/SKILL.md` and the scripts under
  `archive/skills/swt-commit/scripts/` — never naked `git commit -m`.
- Ask before any structural change.
```

**`/home/jason/tools/swt/README.md`:**
```markdown
# SWT — Under Refactor

This repository is mid-refactor. The previous Simple Workflow Toolkit has
been archived to `./archive/` for reference.

- **Previous SWT (frozen snapshot):** see `./archive/README.md`
- **Forward direction:** see `./SWT_FLOW_SEPARATION_IDEATION.md`
- **Archived commit ritual:** `./archive/skills/swt-commit/SKILL.md`
```

### Phase E — Commit (single chore commit, --no-verify bypass)

```bash
cd /home/jason/tools/swt

# Stage everything
git add -A

# Capture a one-line status for the commit message
git status --short | head -20

# Commit. Use --no-verify because the pre-commit hook blocks taskless
# commits (per AGENTS.md §7). This archive move is the precondition for
# any future task to exist; documented as a one-time OOB bypass.
git commit --no-verify -F /tmp/archive-commit-msg.txt
```

**Commit message (write to `/tmp/archive-commit-msg.txt` first, then use `git commit -F`):**
```
chore: archive swt-as-of-2026-09-07

Frozen the entire current SWT as a reference snapshot under ./archive/.
Root keeps only a stub AGENTS.md, stub README.md, .gitignore, and the
forward-looking brief (SWT_FLOW_SEPARATION_IDEATION.md).

This snapshot is the reference material for the flow-separation refactor
described in the brief. Old loop harness, jailbreak-targeted artifacts,
skill catalog, assessments, tests, and tooling all preserved under
archive/ for traceability.

Deleted (all gitignored/ephemeral, no archival value):
- .digests/ .specs/ .tasks/ graphify-out/ demo/ task.ctx
- commit.draft commit.task commit.diff if present

Bypass: --no-verify used. Justification: this chore commit predates any
active task file and is the precondition for starting the refactor task.
The full swt-commit ritual will be honored for the next (refactor) commit,
using the archived swt-commit skill at archive/skills/swt-commit/.
```

### Phase F — Verify commit

```bash
cd /home/jason/tools/swt
git log -1 --stat | head -50
# Confirm the commit landed and shows the expected file moves
```

---

## 6. Business Logic & Invariants

### Invariants (must hold after execution)

1. **Root has exactly five entries** (besides `.git/`): `.gitignore`, `AGENTS.md`, `README.md`, `SWT_FLOW_SEPARATION_IDEATION.md`, `archive/`.
2. **`archive/` contains byte-identical copies** of the source content (no rewriting during the move).
3. **Nothing in `archive/` is modified after the move** — the snapshot is frozen.
4. **Exactly one commit is created** — `chore: archive swt-as-of-2026-09-07`.
5. **`task.ctx` does not exist** post-archive. The refactor will create a new task when it begins.
6. **The brief `SWT_FLOW_SEPARATION_IDEATION.md` is unchanged** at root.

### Failure Modes

| Failure | Detection | Response |
|---|---|---|
| Root contains unexpected file after move | `ls -la` check in Phase C | STOP. Do not commit. List the unexpected file. |
| `archive/` is missing a folder that was at root pre-move | Diff `ls archive/` against the expected list in Phase C | STOP. Investigate which `mv` failed. |
| Pre-commit hook rejects commit | Hook error message | Confirm `--no-verify` is in the command. Retry. |
| `git mv` complains about submodules or symlinks | Error message | Use plain `mv` and `git add -A` to re-stage. |
| Commit message has typos | Read `/tmp/archive-commit-msg.txt` before `git commit -F` | Fix the file, do `git commit --amend -F /tmp/archive-commit-msg.txt` if already committed. |

---

## 7. Security & Safety

- **No network access required.** All operations are local filesystem.
- **No secrets involved.** The gitignored `.env*` rules are preserved in the new `.gitignore` stub.
- **No destructive operations on tracked code in git history.** Files are moved, not deleted from history. `git log` and `git checkout` can recover any pre-archive state.
- **`--no-verify` is a documented, single-use bypass.** Future commits must use the archived `swt-commit` ritual.

---

## 8. Verification Checklist

Execute these in order. All must pass before reporting success.

- [ ] `ls -la /home/jason/tools/swt/` shows exactly: `.git/`, `.gitignore`, `AGENTS.md`, `README.md`, `SWT_FLOW_SEPARATION_IDEATION.md`, `archive/`
- [ ] `ls /home/jason/tools/swt/archive/` shows: `ARCHITECTURE.md`, `CLAUDE.md`, `CONFIG.md`, `GEMINI.md`, `JAILBREAKS.md`, `LOOPS.md`, `MODERNIZE_AGENT_DISCOVERY_PROMPT.md`, `PRD-swt-preview.md`, `README.md`, `SKILLS.md`, `swt.json`, `swt-skills-audit.json`, `.gitignore`, `docs/`, `scripts/`, `skills/`, `tests/`
- [ ] `cat /home/jason/tools/swt/AGENTS.md` shows the stub content from Phase D
- [ ] `cat /home/jason/tools/swt/README.md` shows the stub content from Phase D
- [ ] `cat /home/jason/tools/swt/.gitignore` shows the minimal stub from Phase D
- [ ] `diff -q /home/jason/tools/swt/archive/.gitignore <(git show HEAD~1:.gitignore)` returns 0 (or confirms the archived gitignore matches the pre-archive version)
- [ ] `git log -1` shows `chore: archive swt-as-of-2026-09-07`
- [ ] `git status` is clean

---

## 9. Out of Scope (Explicit)

- The refactor described in `SWT_FLOW_SEPARATION_IDEATION.md`
- Creating a new `.tasks/` file for the refactor
- Running any test suite
- Symlinking or installing any skill
- Modifying anything under `archive/`

---

## 10. Reporting Template

When done, the executing agent should report:

```
## Archive Move — Report

### Final root listing
[paste `ls -la` output]

### Final archive listing
[paste `ls archive/` output]

### Commit
[paste `git log -1 --stat | head -50` output]

### Issues encountered
[none, or description]

### Bypass used
[Yes: --no-verify for the documented chore commit. / No: pre-commit hook did not fire.]

### Self-check
- [ ] Root has exactly five entries
- [ ] archive/ contains all expected items
- [ ] Stub files written with the exact content from Phase D
- [ ] Single chore commit created
- [ ] git status is clean
```

---

> **Version:** 1.0 — 2026-09-07 — initial PRD for archiving current SWT as reference snapshot
