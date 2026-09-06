# SWT Flakiness Assessment

> Assessment of the Simple Workflow Toolkit (SWT) at `~/tools/swt`, derived from
> a code review conducted 2026-08-17. Confirms and substantiates the user's
> assessment: **SWT is a strong ideating pipeline, but its implementation
> planning and transition state management are flaky.**

---

## Executive Summary

| Area | Verdict | Confidence |
|---|---|---|
| Ideation pipeline (`swt:spec`, Phase 0 brainstorm, graduation) | **Mature / working** | High |
| Implementation planning (`implementation_plan.md`, `protocol.md`) | **Skeletal / inconsistent** | High |
| Transition state management (`state.py`, `twin.py`, root artifacts) | **Contradictory / flaky** | High |

The root cause is architectural: SWT has **multiple, overlapping sources of
truth** for state, and the code base carries **two coexisting state engines**
(the legacy `twin.py` sidecar system and the newer "direct markdown" model)
that contradict each other.

---

## 1. Ideation Pipeline — Mature

The ideation side is the most complete and carefully specified:

- **`swt:spec`** (256 lines) — a rich, opinionated spec generator with clear
  invocation modes, a clarification interview, a canonical template, output
  rules, and quality checklist. Well-developed.
- **Phase 0 brainstorm template** (`swt-task/templates/brainstorm.md`) —
  high-fidelity: Covers, Guidance, Explored Alternatives (Scenario A/B/C),
  Artifact Phase Mapping, Unresolved Questions, Impact Analysis.
- **Graduation ritual** (Phase 0 → 1) — the most carefully specified transition
  in the toolkit, with a mandatory HARD STOP and explicit user consent gate.

**Conclusion:** The user's claim that "it's an ideating pipeline" is accurate.
This is the working half.

---

## 2. Implementation Planning — Skeletal & Inconsistent

### Evidence: Thin templates

The planning artifacts are placeholder shells, not plans:

| Artifact | Size | Content |
|---|---|---|
| `implementation_plan.md` | 25 lines | `{{OBJECTIVE}}`, `{{USER_REVIEW_REQUIRED}}`, `{{OPEN_QUESTIONS}}`, `{{PROPOSED_CHANGES}}`, `{{AUTOMATED_TESTS}}`, `{{MANUAL_VERIFICATION}}` |
| `protocol.md` | 18 lines | 4 placeholder sections + `{{TACTICAL_ROADMAP}}` |
| `task.md` | 3 lines | bare checklist |

None of them produce **wireframes, structured test plans, or phase-by-phase
build prompts** — exactly what the ai-dev-toolkit's `swt:devkit` provides.
SWT's planning layer delegates all substance to the agent's judgment.

### Evidence: Artifact naming is internally inconsistent

`state.py:335-342` expects companion artifacts named:

```python
if type == "implementation_plan": ext = "plan.md"
elif type == "protocol": ext = "tr.md"
elif type == "walkthrough": ext = "walkthrough.md"
```

i.e. `{ts}.plan.md`, `{ts}.tr.md`, `{ts}.walkthrough.md`.

But the actual template directory (`swt-task/templates/`) contains
`implementation_plan.md`, `protocol.md`, `task.md`, `spec.md`, `brainstorm.md` —
**no `tr.md` or `walkthrough.md` template exists**, and `implementation_plan.md`
doesn't match the `{ts}.plan.md` pattern the state engine generates.

Additionally `get_backlog()` (`state.py:177`) skips files ending in
`.plan.md`, `.tr.md`, `.walkthrough.md` — artifacts that don't align with any
real template. The state engine and the scaffold command **disagree on what the
planning artifacts are called**.

**Conclusion:** Implementation planning is skeletal and its artifact naming is
internally contradictory. The user's "flaky" claim is substantiated.

---

## 3. Transition State Management — Contradictory & Flaky

This is the weakest area.

### Evidence A: Two coexisting state architectures

`ARCHITECTURE.md` §5 declares the **"Direct Markdown State Engine
Architecture"** — sidecars eliminated, Markdown AST as the authoritative source:

> "eliminating the need for persistent disk-level sidecar files (.yaml or .json)
> inside system folders (.tasks/, .specs/, and .digests/)"

Yet the legacy sidecar engine **`twin.py` (33 KB)** still lives in
`swt-task/scripts/`, and the state sensor `sensor_twin_protocol`
(`state.py:228-287`) still:
- checks for `{file}.yaml` sidecars and compares mtimes
- detects `\n` debris in YAML sidecars
- warns about `--harvest` / `--synthesize` operations

...with a **bypass for exactly the system paths** the new architecture claims
sidecars were removed from:

```python
if any(x in parts for x in (".tasks", ".specs", ".digests")):
    result["findings"].append("Direct Markdown state verified. Sidecars bypassed for system folders.")
    return result
```

So the sensor is effectively **dead code for system paths** — it only runs for
root-level files, and even then references a deprecated engine. This is the
single strongest piece of evidence for flakiness: the architecture doc says one
thing, the shipped code implements the other, and the sensor papers over the gap.

### Evidence B: Divergent root detection

`state.py`'s `find_root_dir()` ascends to the first ancestor containing
`AGENTS.md`, `.git`, or `swt.json`.

`flow.sh` has its own root detection (ascends for `AGENTS.md` or `.git`).

In a project nested inside a parent git repo (or a monorepo), these two can
resolve to **different roots**, so the state report and the orchestrator may
operate on different workspaces.

### Evidence C: Multiple overlapping state artifacts

Behavior is gated by all of the following, with no single authority:

- `task.ctx` (mounted task pointer)
- `.visibility_lock` (flow.sh interlock file)
- root `task.md` (live checklist, synced from task file)
- `implementation_plan.md`, `protocol.md` (root planning artifacts)
- `swt.json` → `ritual_gates` (three boolean feature flags)
- task file headers (`Phase`, `Status`, `Priority`, `Type`, `Category`)

Each has its own sync logic (sync, sync-docs, sync-roadmap, scaffold), creating
drift risk whenever one is updated out of band.

### Evidence D: Monolithic transition logic

`task.sh` is a **50 KB shell script** where most transition logic lives
(graduate, phase, close, abandon, tidy, jailbreak). High surface area for
edge-case failures, and hard to reason about or test exhaustively.

**Conclusion:** Transition state management has contradictory architectures,
divergent root detection, overlapping state artifacts, and monolithic
implementation. The user's "flaky" claim is substantiated.

---

## 4. What This Means for the ai-dev-toolkit Integration

The assessment **validated the "docked, not welded" strategy** used when
converting the toolkit into skills (`skills/swt-*`):

1. **`swt:devkit` fills the exact gap** — SWT's implementation planning is
   skeletal; the toolkit's devkit produces `WIREFRAMES.md`, `TEST_PLAN.md`,
   `AI_PROMPT.md`, `AGENTS.md`. It is the missing planning layer.
2. **New skills are deliberately stateless** — they write to project root /
   `docs/` only, never touching `.tasks/`, `.specs/`, `task.ctx`, sidecars, or
   `flow.sh` routing. Verified by grep: the only reference to transition state
   in `skills/` is the explicit prohibition in
   `swt-devkit/SKILL.md:38`.
3. **Deployment reuses only SWT's solid parts** — the installer
   (`swt-link/scripts/install.sh`) is simple and correct; it copies `skills/*`
   into `~/.agents/skills` + `~/.claude/skills`.

### Why this decoupling is safe

- The new skills cannot break SWT's fragile transition machinery.
- SWT's flaky transitions cannot break the new skills.
- The skills remain fully usable standalone (e.g. in `~/.agents/skills/`
  without SWT at all).

---

## 5. Recommendations (if SWT planning/transition layers are to be hardened later)

1. **Pick one state model.** Either commit fully to "direct markdown" and
   delete `twin.py` + `sensor_twin_protocol`'s sidecar logic, or resurrect the
   sidecar model consistently. Do not ship both.
2. **Reconcile artifact naming.** Decide once: `implementation_plan.md` vs
   `{ts}.plan.md`, `protocol.md` vs `{ts}.tr.md`. Make `state.py`,
   `get_backlog()`, the templates, and the scaffold command agree.
3. **Unify root detection.** Extract a single shared `find_root()` used by
   `state.py`, `flow.sh`, and `task.sh`.
4. **Adopt `swt:devkit` outputs as the planning layer.** Replace the skeletal
   `implementation_plan.md`/`protocol.md` flow with the toolkit's
   `WIREFRAMES.md`/`TEST_PLAN.md`/`AI_PROMPT.md`/`AGENTS.md`, which carry real
   structure.
5. **Break up `task.sh`** into smaller, testable command modules.