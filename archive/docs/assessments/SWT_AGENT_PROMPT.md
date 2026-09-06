# SWT Agent Prompt — Transition-State Flakiness Assessment & Redesign

> Drop this into an agent operating inside `/home/jason/tools/swt`. The goal is
> two-fold: (A) independently assess the flakiness of SWT's transition-state
> machinery, then (B) propose the **simplest** possible redesign. Treat the
> assessment as evidence for the redesign. Do not trust the docs — trust the
> code.

---

## Prompt

```
You are an independent reviewer working inside the SWT repository at
/home/jason/tools/swt. Do NOT trust the docs — trust the code. Verify every
claim by reading the source and tracing control flow. Cite `file:line` for
every finding.

Goal: assess transition-state flakiness, then propose a BETTER (simpler)
design for managing transition state. Treat the assessment as evidence for
the redesign.

## Part A — Assessment (evidence first)

Review the task phase machine (commands: graduate, phase, validate, sync-docs,
close, abandon — canonical source `skills/swt-task/scripts/task.sh`), the state
sensor/report (`skills/swt-flow/scripts/state.py`), the flow orchestrator
(`skills/swt-flow/scripts/flow.sh`), and the planning-artifact lifecycle.
`skills/` is canonical; flag drift in `.claude/skills`, `.agents/skills`,
`demo/`.

Answer with verdict + file:line evidence:

1. TRANSITIONS: does each transition produce a task file the validator
   accepts? Can the tool reach a state it then refuses to validate
   (especially graduate and sync-docs)?
2. STATE WRITERS: enumerate every code path that mutates the task file
   (shell sed/cat vs twin.py harvest→synthesize). Do they agree on what
   "current phase" means? Any ordering hazards or silent content loss?
3. SOURCES OF TRUTH: list every artifact that encodes state (header meta,
   ritual-log breadcrumbs, root task.md, sidecars, swt.json gates, lock
   files). Which are authoritative vs derived? Where can they drift?
4. GATES/INTERLOCKS: for each gate/lock (GATE approvals, .visibility_lock,
   yolo mode), is it ever created/removed? Is enforcement consistent between
   transition-time and validation-time? Are its enabling flags actually
   declared in swt.json, or silently defaulted?
5. ARCHIVE PATHS: what do close/abandon/tidy each archive? Anything orphaned
   (task/spec/sidecars)?
6. SENSORS: do state.py and validate use consistent thresholds/criteria for
   the same condition (e.g. mtime drift)?

## Part B — Design proposal (the point)

Using the evidence from Part A, propose a concrete redesign that ELIMINATES
the drift class of bugs. The bias is toward MINIMAL MACHINERY, not more. Score
candidates partly on how much machinery they delete.

Address:
1. Single source of truth: pick WHERE state authoritatively lives. Prefer the
   smallest possible store — e.g. the task file header meta, or an append-only
   event log embedded in the task markdown. What derives from it, and what is
   NEVER stored twice?
2. Single writer: specify the one code path every transition must go through,
   and how it stays the only writer (no sed/cat/twin rewrite mix).
3. Producer/validator agreement: how the validator is kept consistent with
   what transitions legally emit (e.g. one shared transition spec/table that
   generates both handlers and the checks).
4. Deletions: explicitly list every artifact/mechanism the current design has
   that the new design REMOVES (sidecars, breadcrumbs-as-invariant, root
   task.md sync, lock files, gates).
5. Migration: what changes to task.sh/state.py/twin.py/flow.sh/ARCHITECTURE.md,
   and how existing tasks are migrated without loss.

## Output format

- Executive summary (3 lines per area)
- Part A findings: severity (Critical/High/Med/Low) + file:line + reproduce
  trigger + proposed fix
- Part B: ONE recommended design + 1-2 alternatives with tradeoffs, including
  which bugs each resolves and what new risks it adds. Include a "machinery
  diff": current artifacts/writers/gates → new, with counts.
- Severity-ranked table + bottom line

Investigate thoroughly. Trace full command → writer → validator paths and show
why something breaks, rather than asserting it.
```

---

## Notes for the human operator

- **Why this prompt:** every flakiness finding in the accompanying
  assessments reduces to "two of something" (two writers, two stores, two
  modes, two thresholds). The prompt steers the agent to measure the drift
  surface and then to *minimize* it, not patch it.
- **The root motive is jailbreak defense.** `JAILBREAKS.md` shows the
  machinery accreted as countermeasures to agent protocol violations — each
  gate (breadcrumbs, task.ctx, facade, sidecars, visibility_lock) was added
  to stop a bypass, then itself got bypassed. The fatal pattern was
  countering state-faking with *more state*. So the redesign constraint is:
  **do not let Part B add any new verifiable state to catch a forger — it
  will be forged too.** Real jailbreak deterrents are HITL consent gates +
  a single immutable source of truth + the git audit trail.
- **"Do not mention the ai-dev-toolkit"** — this prompt is self-contained for
  the SWT repo; it does not reference the new skills, so the agent can't be
  led by (or confused about) the integration strategy.
- **Known anchors to watch for** (the agent should rediscover these, not be
  told): `task.sh:848` graduate logs an unsigned ritual; `task.sh:917-919`
  sync-docs resets Phase without pruning older rituals; `flow.sh:328`
  visibility_interlock silently defaults True; two writers at `task.sh:47`
  vs `twin.py:781`.