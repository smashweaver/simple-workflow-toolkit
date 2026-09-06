# SWT Flow Separation — Ideation Seed

> **Purpose**: A self-contained brief to feed an AI agent for SWT task ideation.
> It documents a design direction (separate flows instead of one interconnected
> phase chain), two locked decisions, verified code evidence, and open questions
> the agent should resolve during Phase 0 brainstorm.
>
> **Created**: 2026-08-18
> **Status**: ideation input — not an approved spec

---

## 1. Context & Motivation

- The ai-dev-toolkit (previously "SWT-compatible skills") has been decoupled
  into a standalone `adt:*` toolkit. It no longer depends on SWT, and SWT's own
  design can now be reconsidered on its own merits.
- SWT's transition machinery was assessed as fragile (see
  `docs/assessments/SWT_*_ASSESSMENT.md`). A recurring root cause: the single
  `Phase: N` chain fuses concerns that should be independent.
- This brief proposes splitting the one chain into **separate flows**.

## 2. The Problem — Interconnected Flows

Today a single phase number drives everything. The spec, plan, commit, protocol,
and task all read from the same `Phase: N` integer, and commands mutate multiple
artifacts at once. Verified couplings:

| Coupling | Evidence | Direction |
|---|---|---|
| spec ↔ task | `state.py:318-331` — substance drift: hashes task substance vs spec substance | `sync-docs` re-synthesizes spec from task (`task.sh:910`) then resets task to Phase 1 (`task.sh:917`) |
| spec ← created by graduate | `task.sh:853-859` scaffolds spec; `task.sh:866-871` appends plan + protocol INTO task | one command creates 3 artifacts |
| plan ↔ task | `task.sh:149` — Phase ≥1 requires Implementation Plan (embedded or sidecar) | plan is redundant with spec §6 |
| commit ↔ task | commit is literally Phase 8 (`state.py:50`, `VALID_NEXT[8]`); sensors poll `commit.draft`/`commit.task` (`state.py:355-410`) | commit cannot exist without the whole chain |
| commit ↔ spec | `task.sh:940-962` — `close` archives plan INTO spec | spec becomes a tombstone |
| commit ↔ repo | pre-commit hook (`skills/swt-task/scripts/hooks/pre-commit`) blocks taskless commits | git is coupled to task lifecycle |

**The failure mode**: fixing any one flow risks breaking the others. Each
"improvement" added a new source of truth and a new cross-check (the
compensation spiral in `docs/assessments/SWT_COMPLEXITY_SPIRAL_ASSESSMENT.md`).

## 3. Locked Decisions

### D1 — Remove `swt:spec`, replace with `swt:plan`

- The spec and the implementation plan overlap (spec §6 is an Implementation
  Plan; plan is separately embedded in the task). Two artifacts, one purpose.
- Target: **one planning artifact** — `swt:plan` — that owns requirements +
  implementation steps.
- Implication: `.specs/` machinery, spec template, substance-drift sensor, and
  spec re-sync in `sync-docs` can be removed.

### D2 — Refactor transition state to separate flows

- Replace the single linear `Phase: N` chain with independent flows, each owning
  its own state, artifacts, and gates.
- **Commit is the motivating example**: it is a git operation. It should not be
  Phase 8 of a development chain, and it should not carry orphan detection
  (`state.py:355-358`), sensor logic (`state.py:392-474`), or spec-archiving
  (`task.sh:940-962`).

## 4. Proposed Target Architecture

```
Flow 1: IDEATION       task file → graduate →           (was Phase 0→1)
Flow 2: PLANNING       swt:plan authors plan → Gate 2   (was Phase 1-4)
Flow 3: EXECUTION      implement → test →               (was Phase 5-7)
Flow 4: COMMIT         draft → lint → approve → close   (was Phase 8)
```

Each flow owns its own:

- **State** — how far along the flow is (not a global phase integer)
- **Artifacts** — task file for ideation, plan for planning, code/tests for
  execution, commit.draft/hash for commit
- **Gates** — e.g., Gate 2 (HITL approval) belongs to PLANNING; lint belongs to
  COMMIT

Key changes implied:

1. `swt:plan` absorbs spec content (problem, goals, user stories, NFR, risks,
   MVP) plus implementation steps.
2. Commit decoupled: its own skill/lifecycle; not "Phase 8"; sensors and orphan
   checks removed from `state.py`. Pre-commit hook may remain as a pure
   "task mounted?" gate.
3. `close` no longer writes into spec.
4. Task file tracks which flow it is in — a `Flow:` field or per-flow state.

## 5. Open Questions (for the agent to resolve in Phase 0)

1. **Scope**: surgical (only plan + commit) vs full rewrite (LOOPS.md,
   `state.py`, `flow.sh`, `task.sh`, all sensors)?
2. **Phase numbers**: keep `Phase: N` per-flow for backwards compatibility, or
   adopt flow-specific naming (`Flow: planning`)?
3. **Spec migration**: hard-delete `.specs/` + `swt:spec` + drift sensor, or
   soft-deprecate (keep skill, stop machinery)?
4. **Stateless `swt:plan`**: should `swt:plan` be a stateless authoring skill
   (like `adt:devkit` — no transition-machinery coupling), or may it invoke
   transition state?
5. **Flow representation**: what is a "flow" in the task file — a field, a
   per-flow counter, or derived from artifact presence?
6. **Existing tasks**: how do currently-open tasks (all Phase 0) migrate to the
   new model without loss?
7. **Validation**: what does `validate` check under separate flows? What becomes
   simpler vs what needs new checks?

## 6. Constraints & Guardrails

From the SWT assessments (see `docs/assessments/`):

- **No new forgeable state.** Each gate added historically to stop a bypass was
  then bypassed (`JAILBREAKS.md`). Do not add shadow state to catch a forger.
- **Real controls = HITL consent + git audit trail.** Human approval and git
  history are the trustworthy controls, not more sensors.
- **Prefer removing machinery over adding it.** Every removal of a cross-check
  that no longer applies is a win.
- **Keep `swt:plan` minimal and reusable.** Reuse existing twin/validate
  machinery rather than forking logic.

---

## Appendix A — Quick Reference: files touched by the current design

| File | Role |
|---|---|
| `skills/swt-flow/scripts/flow.sh` | unified facade, subcommand routing, visibility interlock |
| `skills/swt-flow/scripts/state.py` | transition state recognizer (5 sensors) |
| `skills/swt-task/scripts/task.sh` | lifecycle: graduate, phase, validate, sync-docs, close, abandon |
| `skills/swt-task/scripts/twin.py` | Global Twin — markdown/YAML state synthesis |
| `skills/swt-task/templates/{spec,implementation_plan,protocol}.md` | artifact templates |
| `skills/swt-spec/SKILL.md` | spec generation skill (candidate for removal) |
| `skills/swt-commit/SKILL.md` + `scripts/` | commit flow (candidate for decoupling) |
| `LOOPS.md` | authoritative loop/gate visualization |
| `swt.json` | ritual_gates config |