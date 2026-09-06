# Product Requirements Document (PRD)
# swt-preview — Standalone Markdown Preview Skill

> **For AI Coding Agents:** Read this file first. This is the single source of truth.
> All implementation decisions must align with this document.

---

## 1. Product Overview

**Name:** swt-preview  
**Tagline:** Preview any Markdown file as a styled HTML dashboard in one command — no workflow loop required.  
**Type:** CLI Skill (SWT Toolkit extension)  
**Target User:** SWT users and AI agents who want to render `PRD.md`, `README.md`, `docs/*.md`, or any `*.md` without invoking `swt:flow` gates. Solo devs who prefer manual phase control (direct `skills/*` invocation over `swt:flow` facade).  
**Core Value:** Turns the hidden `swt:flow open` capability (`flow.sh:183` + `twin.py --synthesize` → `.cache/*.html` → `xdg-open`) into a discoverable, standalone skill with no `task.ctx` jailbreak warning and no 8-phase ceremony.

---

## 2. Goals & Non-Goals

### Goals (Must Have for MVP)

- [ ] `swt:preview <file.md>` opens any markdown file (not just `task/spec/digest`) as SWT-styled HTML (light/dark, `Fira Code`, card layout) via `twin.py --synthesize` → `.cache/<base>.html` → `xdg-open` (fallback `firefox|google-chrome|chromium`)
- [ ] No `task.ctx` gate — no `⚠️ No active task mounted` warning, no `visibility_lock` interlock, no `Phase 4 HARD STOP` — pure preview
- [ ] Preserves the two fixes proven in PRD `0.0.3→0.0.7` session: handles both `  ` hard breaks and `<br>` tags, and auto-inserts `<br>` for consecutive `**Key:**` meta lines so clean MD renders correctly
- [ ] Lists as `swt:preview` in `SKILLS.md` and `swt.json` (user-invocable, `allowed-tools: [Read, Bash]` only — no `Write`)
- [ ] Equivalent to `skills.sh` inventory — `bash skills/swt-preview/scripts/preview.sh <file>` works stand-alone without `swt:flow`

### Non-Goals (Post-MVP / Out of Scope)

- [ ] Editing the markdown file (read-only preview)
- [ ] Replacing `twin.py` synthesis with a custom `md2html.js` (reuse existing engine; the `/tmp/md2html.js` workaround is deprecated)
- [ ] Adding `task.ctx` mounting, `Phase` tracking, or `Spec` linkage (that's `swt:flow` / `swt:task` territory)
- [ ] PDF export — HTML preview only (printing via browser covers it)

---

## 3. User Personas

### Primary: Solo Dev — "Manual Phase" (you)

- Solo developer using SWT but bypassing `swt:flow` loop for speed; calls `bash skills/...` directly
- Pain points: `flow.sh:79` jailbreak warning on every `open` without `task.ctx`; wants `swt:preview README.md` in one line without creating a task
- Current tools: `bash flow.sh open <file>`, `/tmp/md2html.js` hack, `xdg-open` manually
- Tech comfort: high

### Secondary: Designer / Reviewer

- Needs to review `PRD.md` or `docs/*.md` as styled HTML without understanding SWT phases
- Pain points: raw markdown hard to read in terminal; `swt:flow status` interlock blocks simple preview
- Tech comfort: medium

---

## 4. User Stories

### Epic 1: Preview Any Markdown

- As Solo Dev, I want `swt:preview PRD.md` so that I see the styled HTML without creating a task or mounting context.
- As Reviewer, I want `swt:preview docs/PRD-2026-platform-agnostic.md` so that the `**Version:**` meta renders with line breaks (no collapsed `**Version:** ... **Status:**` single-paragraph bug).
- As Agent, I want a skill that maps directly to `skills.sh` inventory (`preview.sh`) so that I can invoke it without routing through `swt:flow`.

### Epic 2: No Workflow Friction

- As Solo Dev, I want no `⚠️ No active task mounted` warning when previewing so that OOB reading is not flagged as jailbreak.
- As Solo Dev, I want the command to work from any `ROOT_DIR` (detected via `AGENTS.md` or `.git`) so that I can call it from `MVCStore/` or `~/tools/swt/`.

### Epic 3: Consistent Styling

- As Designer, I want the HTML to use SWT's `twin.py` dashboard style (as in `.cache/PRD-2026-platform-agnostic.html` 50K) so that PRDs look identical whether via `swt:flow open` or `swt:preview`.

---

## 5. Data Model

### Entity: PreviewRequest

| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| input_path | string | Absolute or `ROOT_DIR`-relative `*.md` path |
| cache_path | string | `ROOT_DIR/.cache/<base>.html` |
| created_at | timestamp | Compilation time |
| updated_at | timestamp | Re-compilation on re-run |

> Note: No persistent DB needed — file-system only. Model shown for spec completeness; `created_at/updated_at` = file `mtime`.

---

## 6. Page Flows

### Flow 1: Preview Existing Markdown (happy path)

1. User runs `swt:preview docs/PRD.md` or `bash skills/swt-preview/scripts/preview.sh docs/PRD.md`
2. Script resolves `ROOT_DIR` (ascend to `AGENTS.md` or `.git`); validates `input_path` exists and is `*.md`
3. Script ensures `.cache/` exists; runs `uv run python3 skills/swt-task/scripts/twin.py <input> --out .cache/<base>.html --synthesize`
4. On success (`-f .cache/<base>.html`), script calls `open_browser` (`xdg-open` → `firefox` → `google-chrome` → `chromium` fallback, as in `flow.sh:100`)
5. Shell prints `⚡ Compiling visual dashboard for <base>...` and `🌐 Attempting to open: <base>.html`

### Flow 2: File Not Found

1. User runs `swt:preview missing.md`
2. Script prints `❌ Error: Target file 'missing.md' not found.` and exits `1` (mirrors `flow.sh:198`)

### Flow 3: Non-Markdown (future)

1. User runs `swt:preview image.png`
2. Script opens directly via `open_browser` without `twin.py` synthesis (mirrors `flow.sh:227` else branch)

---

## 7. UI/UX Requirements

### Design Direction

- Mood: same as `swt:flow open` — clean, `Fira Code`, light/dark auto via `prefers-color-scheme`, card layout (`--bg-color: #f3f4f6` light / `#0b0c10` dark)
- Reference: existing `.cache/PRD-2026-platform-agnostic.html` (50K) and digest dashboards (`.cache/*_digest.html`)
- Density: spacious (SWT dashboard standard)

### Key Screens

1. **Dashboard HTML** — header `Version/Status/Changelog` meta with `<br>` line breaks (fixed `0.0.7`), HR, Vision, Goals, Components table, Production Readiness checklist

### Responsive

- Desktop only (SWT cache preview is desktop browser; no mobile layout needed)

---

## 8. Business Logic

### Compilation Rule

```
if input_path endswith .md:
  cache_path = ROOT_DIR/.cache/<basename(input_path)>.html
  uv run python3 SKILLS_DIR/swt-task/scripts/twin.py <input_path> --out <cache_path> --synthesize
  if cache_path exists: open_browser(cache_path)
else:
  open_browser(input_path)
```

### Browser Fallback Chain

```
xdg-open > firefox > google-chrome > chromium > error "No browser command"
```

### No-Gate Rule

- Skill never reads `task.ctx` and never checks `visibility_lock` or `swt.json` `ritual_gates` — preview is always allowed, even with no active task.

---

## 9. Security Requirements

- Read-only: `allowed-tools: [Read, Bash]` — no `Write` or `Edit`
- No secrets, no auth; preview is local file → local browser only
- Input validation: reject `../` traversal outside `ROOT_DIR`? No — allow any absolute `*.md` (same as `flow.sh open`); no network fetch

---

## 10. Performance Requirements

- Compile `PRD (183 lines)` → HTML `< 500ms` (`twin.py` warm `uv` cache)
- Cache file `< 100KB` (current `50K`)
- `xdg-open` async (`&`) — shell returns immediately, no blocking (as in `flow.sh:111` `>/dev/null 2>&1 &`)

---

## 11. Tech Stack

| Layer | Technology |
|---|---|
| Frontend | HTML synthesized by `twin.py` (no JS framework) |
| CSS | SWT dashboard tokens (`--bg-color`, `Fira Code`) |
| Backend | Bash `skills/swt-preview/scripts/preview.sh` + Python `swt-task/scripts/twin.py` |
| Database | File-system (`.cache/*.html`) |
| Auth | None |
| Deployment | `scripts/install-skill.sh` → `~/.agents/skills/swt-preview/` (Physical Mode, Stable) |

---

## 12. MVP Scope

### Phase 1 (Week 1): Scaffold Skill

- [ ] Create `skills/swt-preview/SKILL.md` (name `swt:preview`, `inherits: swt:think`, `user-invocable: true`, `allowed-tools: [Read, Bash]`)
- [ ] Create `skills/swt-preview/scripts/preview.sh` (extract `flow.sh:100` `open_browser` + `flow.sh:183-229` `open` logic, minus `task.ctx` gate)
- [ ] Add entry to `SKILLS.md` and `swt-skills-audit.json`

### Phase 2 (Week 1): Wire Compiler

- [ ] Ensure `preview.sh` calls `twin.py --synthesize` correctly for clean MD (no `  ` required) — reuse the `0.0.7` fix (`<strong>...\n<strong>` → `<br>`)
- [ ] Test `swt:preview PRD-2026-platform-agnostic.md` (6 meta lines → 5 `<br>`) and `docs/*.md`

### Phase 3 (Week 1): Browser Fallback

- [ ] Test `xdg-open` → `firefox` → `google-chrome` → `chromium` chain on Linux (as in `flow.sh:100`)
- [ ] Handle non-`.md` passthrough

### Phase 4 (Week 1): Install & Docs

- [ ] `scripts/install-skill.sh` physical install test; verify `skills.sh` lists `swt-preview`
- [ ] README snippet: `swt:preview <file.md> — preview any markdown without workflow`

### Phase 5 (Week 1): Validation

- [ ] `open PRD-2026-platform-agnostic.md` via new skill matches `.cache/PRD-2026-platform-agnostic.html` from `swt:flow open` (byte-identical sans `task.ctx` warning)

---

## 13. Open Questions

- [ ] Should `swt:preview` also support `stdin` (`cat PRD.md | swt:preview -`) for pipe workflows?
- [ ] Should the cache be `.cache/preview/<base>.html` vs. `.cache/<base>.html` to avoid colliding with `swt:flow open` cache?
- [ ] No equivalent in `skills.sh` today (`ls skills/` shows no `swt-preview`) — confirmed, so this is net-new; should `skills.sh` be retired or kept as alias?

---

> **Version:** 0.0.1 — 2026-08-31 — initial PRD for standalone `swt-preview` skill (extracted from `swt:flow open` + `/tmp/md2html.js` hard-break fix)

