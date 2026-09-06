# SWT Agent Briefing — How to Use These Docs

> Purpose: tell an agent operating inside `/home/jason/tools/swt` **what to
> focus on**, consolidating everything discovered across the four assessment
> documents and this conversation's live verification. Read this first, then
> pick the directives below and paste the ones you want.

---

## 1. Doc Map — Which Doc Is For What

| Doc | Role | Use it when you need |
|---|---|---|
| `SWT_AGENT_PROMPT.md` | The **drop-in prompt** | The full assess→redesign exercise, ready to paste |
| `SWT_FLAKINESS_ASSESSMENT.md` | The **big picture** | Confidence that SWT = mature ideation + flaky transitions |
| `SWT_STATE_TRANSITION_ASSESSMENT.md` | The **F1–F10 hit list** | Every specific transition bug with `file:line` + fix |
| `SWT_COMPLEXITY_SPIRAL_ASSESSMENT.md` | The **meta-diagnosis** | *Why* it's flaky: compensation spiral, jailbreak motive |
| `SWT_AGENT_BRIEF.md` (this file) | The **operator's manual** | How to turn the above into focused agent directives |

---

## 2. What Was Discovered (the findings the agent must respect)

1. **F1–F10** — the specific defects: graduate's unsigned ritual, sync-docs
   leaving stale rituals, GATE 2 grep mismatch, yolo/validate inconsistency,
   two competing writers, threshold mismatch, archive orphans, dead
   sync path, PCRE `grep -oP`.
2. **Correction (live verification):** F4 was **superseded** — `.visibility_lock`
   IS wired (`flow.sh:325,337`). The real bug is `visibility_interlock` being
   **absent from `swt.json`** and silently defaulting to `True`
   (`flow.sh:328`). Don't let the agent rediscover the stale "phantom gate"
   claim — point it at the silent-default instead.
3. **The complexity spiral** — every open task adds machinery; none subtracts
   (lexicon skill, plan-first skill, third state architecture all queued).
4. **The root motive: jailbreak defense** — `JAILBREAKS.md` shows each gate
   was added to stop a bypass, then got bypassed. Countering a state-faker
   with *more state* is self-defeating. Constraint for Part B: **no new
   verifiable state to catch a forger.**
5. **The documented-but-abandoned intent** — the archived
   `phase-transition-ritual-fix` spec already rejected "shadow state"; the
   task file must remain the single source of truth.
6. **Author-oblivion** — the author can't recall the purpose of his own gate.
   Proof the machinery outlived the understanding.
7. **The design north star** — minimal machinery: one source of truth, one
   writer, one transition table generating both handlers and validator,
   deletions list, HITL + git as the real anti-jailbreak controls.

---

## 3. Focus Directives — Pick and Paste

### Directive A — Assess only (fastest, read-only)
```
You are an independent reviewer in /home/jason/tools/swt. Do not trust docs —
verify in code, cite file:line. Focus ONLY on transition-state machinery.

For each of the 6 questions below give a verdict + evidence:
1. TRANSITIONS: does each transition (graduate, phase, sync-docs, close,
   abandon) produce a task file the validator accepts? Can the tool reach a
   state it then refuses to validate?
2. WRITERS: enumerate every code path mutating the task file (shell sed/cat
   vs twin.py harvest→synthesize). Do they agree on "current phase"?
3. SOURCES OF TRUTH: list every artifact encoding state (header meta,
   ritual breadcrumbs, root task.md, sidecars, swt.json gates, lock files).
   Which are authoritative vs derived? Where can they drift?
4. GATES: for each gate/lock, is it ever created/removed? Is enforcement
   consistent between transition-time and validation-time? Are enabling
   flags actually declared in swt.json or silently defaulted?
   NOTE: .visibility_lock IS wired (flow.sh:325,337) — the real question is
   whether its visibility_interlock flag is declared or silently True.
5. ARCHIVE: what do close/abandon/tidy each archive? Anything orphaned?
6. SENSORS: do state.py and validate agree on thresholds for the same
   condition (mtime drift)?

Output: severity-ranked findings, each with file:line + reproduce trigger +
proposed fix. Do NOT propose a redesign.
```

### Directive B — Assess + redesign (the full exercise)
Run Directive A's Part A, then:
```
Using that evidence, propose a redesign that ELIMINATES the drift class of
bugs. Bias: MINIMAL MACHINERY. Score candidates partly on how much they delete.

Constraints (non-negotiable):
- The archived phase-transition-ritual-fix spec already rejected "shadow
  state"; the task file is meant to be the single source of truth.
- DO NOT propose any new verifiable state to catch a forger (breadcrumbs,
  signatures, lock files) — it will be forged too. Real anti-jailbreak
  controls are HITL consent gates + the git audit trail.
- One source of truth, one writer, one transition table driving both
  handlers and validator.

Address: where state lives; the single writer path; producer/validator
agreement; an explicit DELETIONS list; and migration for existing tasks.
Output: ONE recommended design + 1-2 alternatives, a "machinery diff"
(current artifacts/writers/gates → new, with counts), and which of these
F-findings each design resolves: F1 (unsigned graduate), F2 (stale rituals
after sync-docs), F5 (yolo/validate mismatch), F6 (two writers), F9 (dead
sync path), F3/F7/F8/F10.
```

### Directive C — Redesign only, given the findings (skip re-assessment)
If you already trust the F1–F10 findings and only want the design:
```
You are a system architect reviewing SWT's transition-state machinery in
/home/jason/tools/swt. These defects are established (verify briefly, don't
re-investigate): graduate's ritual is unsigned and fails validate; sync-docs
leaves stale high-phase rituals making tasks un-validatable; two writers
mutate task files (shell sed/cat vs twin.py full rewrite); yolo skips guards
but validate enforces them; root task.md sync is a dead path; .visibility_lock
is wired but its enabling flag visibility_interlock silently defaults True
because it's absent from swt.json.

Propose the minimal redesign that eliminates this drift class, honoring:
task file = single source of truth, ONE writer, ONE transition table that
generates both handlers and validator, and NO new forgeable state (anti-
jailbreak lives in HITL consent + git audit trail). Include a deletions list
and a migration path for existing tasks. End with a severity-ranked verdict
on which defects each design choice resolves.
```

### Directive D — Pre-flight health check (before any redesign)
```
In /home/jason/tools/swt, run a read-only health check before we plan any
work. Report:
1. /swt:flow status — active task, its Status/Phase, mounted context.
2. Whether .visibility_lock currently exists and why.
3. Whether task.ctx points at a valid file.
4. Open tasks count + the 3 newest by timestamp.
5. Whether the active task file would pass /swt:flow validate right now
   (try it; if it fails, quote the exact validator error).
6. Latest digest timestamp vs today.
Do NOT modify anything. Cite file:line for any code you reference.
```

---

## 4. Sequencing Recommendation (how to actually run this)

1. **Pre-flight (Directive D)** — 2 minutes, establishes current state and
   surfaces the mounted task (`add-transition-engine-hygiene-and-test-suite`,
   still Phase 0). If validate fails on the active task, you've proven F1/F2
   live before spending anything.
2. **Assess (Directive A)** — the independent verification. Compare its
   findings against the F1–F10 doc; the delta tells you what's changed since
   the review date.
3. **Redesign (Directive C)** — once the findings are confirmed, skip the
   re-assessment and get straight to the design. Cheapest path to the
   deliverable that matters.
4. **Adjudicate** — you hold the simplify-vs-harden decision. The current
   mounted task says "do not restructure"; the redesign says restructure.
   This briefing's recommendation: pause the hardening task, adopt the
   simplification, then re-scope the test-suite task to guard the new model.

---

## 5. Rules for Every Directive

- **Never mention the ai-dev-toolkit or the new skills** to the SWT agent —
  the docs and prompts here are self-contained.
- **Never let the agent write to `.agents/`/`.claude/`** (Development
  Guardrail in the active task); canonical source is `skills/`.
- **Read-only for assessment; explicit write approval for redesign.**
- **File:line for every claim.** Trust the code, not the docs.