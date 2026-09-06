# SWT State Transition Tracking — Flakiness Assessment

> Focused deep-dive into **how a task moves through the phase machine**
> (`graduate`, `phase`, `validate`, `sync-docs`, `close`, `abandon`) and where
> that machinery breaks. Complements the broader
> `SWT_FLAKINESS_ASSESSMENT.md`; here every finding is tied to a concrete
> `file:line`. All line numbers refer to `/home/jason/tools/swt` on 2026-08-17.

---

## Executive Summary

| Mechanism | Verdict |
|---|---|
| Transition commands (graduate / phase / close / abandon) | **Mostly functional** |
| Validation gate (`validate`) | **Self-contradictory — rejects its own legal transitions** |
| `sync-docs` (objective-change reset) | **Produces un-validatable tasks** |
| Gate / interlock enforcement | **Phantom gates + skipped gates + mode inconsistency** |
| State writers | **Two competing writers (shell `sed`/`cat` vs twin.py full rewrite)** |

**Root cause:** transition logic is a single 1326-line bash monolith that reads
and writes the task file through **two different mechanisms that don't agree on
what "current phase" means** — a grep header parser and a harvest→synthesize
rewriter — and the validator's breadcrumb rules assume invariants that the
transition commands themselves violate.

---

## 1. The Intended Protocol (as designed)

- `graduate` — Phase 0 → 1. Substance check, sandbox check, twin sets
  `Status=pending Phase=1`, ritual logged, spec scaffolded
  (`task.sh:817-887`).
- `phase <N>` — any N → N. Guarded by `check_phase_transition`, then twin sets
  `Phase` meta, ritual logged **with the "(State Verified)" signature**, then
  `validate_artifacts` (`task.sh:1069-1119`).
- `validate` — the integrity gate. Anti-circling breadcrumb check, forgery
  check, orientation-signature check, staleness, TDD, artifact audit
  (`task.sh:1121-1279`).
- `sync-docs` — on objective change, re-sync Spec and **reset task to Phase 1**
  (`task.sh:889-927`).
- `close <hash>` / `abandon` — set `Status=done|abandoned`, move to archive.

The validator's breadcrumbs are the key invariant: **header `Phase` must equal
the highest ritual-log phase, and every phase's ritual must carry
"(State Verified)"** (`task.sh:1154-1181`).

---

## 2. Findings

### F1 — `graduate` emits a ritual WITHOUT "(State Verified)" → freshly graduated tasks FAIL `validate`

`graduate` logs its phase-1 ritual with **no signature**:

```bash
# task.sh:848
log_ritual "phase 1" "$FILE"
```

…whereas the `phase` command always signs:

```bash
# task.sh:1092
log_ritual "phase $PHASE_NUM" "$FILE" "(State Verified)"
```

`validate` step 2.5 then demands that signature for **every** phase > 0:

```bash
# task.sh:1173-1181
if [ "$PHASE" -gt 0 ]; then
    LATEST_RITUAL_LOG=$(grep "<!-- RITUAL: phase $PHASE" "$FILE" | head -n 1)
    if [[ ! "$LATEST_RITUAL_LOG" =~ "(State Verified)" ]]; then
        echo "🛑 RITUAL DRIFT DETECTED: ..."
        exit 1
```

**Consequence:** `graduate` → `validate` = guaranteed **RITUAL DRIFT**, exit 1.
The workaround ("re-run `phase 1`") is a redundant double-transition. The
0→1 transition path and the validator disagree on the signature contract.

### F2 — `sync-docs` leaves stale high-phase rituals → "AGENT CIRCLING" false positive, task becomes un-validatable

`sync-docs` resets the header to Phase 1 but **never clears older ritual logs**:

```bash
# task.sh:917
invoke_twin "$FILE" --set-meta "Phase" "1" --set-item "Checklist" "Phase 1: Plan" "/"
# task.sh:919
log_ritual "phase 1" "$FILE" "(Reset via sync-downstream)"
```

A task that had reached Phase 5 before the objective change still contains
`<!-- RITUAL: phase 5 ... -->`. The anti-circling check then fires:

```bash
# task.sh:1156-1162
MAX_RITUAL=$(grep -oP '<!-- RITUAL: phase \K\d+' "$FILE" | sort -rn | head -n 1)
if [ "$MAX_RITUAL" -gt "$PHASE" ]; then   # 5 > 1 → TRUE
    echo "🛑 AGENT CIRCLING DETECTED: Header says Phase $PHASE, but ritual logs exist for Phase $MAX_RITUAL."
    exit 1
```

**Consequence:** after any objective change + `sync-docs`, `validate` hard-fails
until rituals are manually pruned. `sync-docs` manufactures an un-validatable
state. Its own reset log ("Reset via sync-downstream") also fails the step-2.5
signature test (see F1 pattern).

### F3 — GATE 2 approval check reads the task file ONLY, but its message says "task or spec"

```bash
# task.sh:426-428
if ! grep -q "GATE 2: APPROVED" "$file"; then
    echo "🛑 GATE 2 LOCKED: Implementation (Phase 5) requires explicit user approval."
    echo "👉 The user MUST append 'GATE 2: APPROVED' to the task or spec before proceeding."
```

The message promises the spec is an acceptable approval location, but the grep
checks only `$file`. Approval written to the spec **never unlocks the gate**.
The magic string `"GATE 2: APPROVED"` is free-form and undocumented anywhere in
the docs — easy to typo, and there's no inverse "denied" state.

### F4 — `.visibility_lock`: NOT a phantom gate (prior assessment superseded)

> **Correction (2026-08-17, live verification):** an earlier draft claimed
> nothing ever writes this file. That is **wrong on the current source** —
> `flow.sh` both creates and removes it:
>
> ```bash
> # flow.sh:337  — created
> touch "$VISIBILITY_LOCK"
> # flow.sh:325  — removed (after status/pulse)
> rm -f "$VISIBILITY_LOCK"
> ```
>
> It fires when: Phase 5 + git dirty + `ritual_gates.visibility_interlock`
> enabled (`flow.sh:326-342`), and blocks non-`status`/`pulse`/`unmount`
> commands (`flow.sh:93`) until the roadmap is surfaced.

**Actual finding, still valid:** the gate flag `visibility_interlock` is read
from `swt.json` (`flow.sh:328`) but is **not present** in the repo's `swt.json`
(which only declares `ballmer_heartbeat`, `phase_order_enforcement`,
`hitl_approval`). So the interlock **silently defaults to `True`** via the
`|| echo "True"` fallback — enabled-by-default machinery the user never opted
into, with no inverse flag to disable it. One more "hidden gate" that behaves
differently than the config suggests.

### F5 — `yolo` mode disables transition guards but `validate` still enforces historical rules

```bash
# task.sh:406
if [ "$SWT_MODE" == "yolo" ]; then return 0; fi
```

In `yolo`, `check_phase_transition` skips **both** phase-order enforcement and
the GATE 2 approval. But `validate` has no mode awareness — anti-circling,
forgery, and orientation checks run regardless (`task.sh:1154-1181`). So
transitions taken in `yolo` produce files that the same toolchain's own
validator rejects. Enforcement is inconsistent between transition-time and
validation-time.

### F6 — two competing state writers: shell `sed`/`cat` vs twin.py full-file rewrite

`log_ritual` and `update` mutate the file with `sed -i`, and `graduate` appends
template output with `cat >>`:

```bash
# task.sh:47  (log_ritual)
sed -i "/^## Ritual Logs/a $entry" "$FILE"
# task.sh:1304 (update)
sed -i "/^## Checklist$/a - [ ] $APPEND_TEXT" "$FILE"
# task.sh:866-871 (graduate)
python3 twin.py "$FILE" --state "$FILE" --template ... --out .tmp_plan.md --synthesize
cat .tmp_plan.md >> "$FILE"
```

…while every `invoke_twin` call then runs a **harvest → `_basic_synthesize`
full-file rewrite** that rebuilds the entire document from harvested state
(`twin.py:781-801`). Any content that doesn't round-trip through harvest (odd
sections, malformed headers, trailing prose) is **silently dropped or
reordered**. There is no guard preventing a shell edit from being clobbered by
the next twin rewrite, or vice versa. Ordering hazards are everywhere — e.g.
`graduate` logs its ritual *before* appending the plan/protocol templates and
*before* the final twin synthesize (`task.sh:848 → 866-871 → 876`), so the
ritual comment's survival depends on twin harvesting it as section content.

### F7 — inconsistent mtime thresholds: state sensor vs hard gate disagree

The twin-protocol sensor flags drift at **> 30 s**:

```python
# state.py:254
if delta > 30:
    result["warnings"].append(f".md is {int(delta)}s newer than sidecar — harvest pending...")
```

…but `validate` tolerates **> 60 s** before failing:

```bash
# task.sh:1200
if [ "$task_time" -gt $((spec_time + 60)) ]; then
```

Same staleness class, two different tolerances → `state` can say "drift" while
`validate` says "clean", confusing agents relying on either.

### F8 — `close` and `abandon` archive the task + sidecars but NOT the Spec → orphans

```bash
# task.sh:974-982 (close)
mv "$FILE" .tasks/archive/
mv "${FILE}.yaml" .tasks/archive/ 2>/dev/null
for _ext in plan.md tr.md walkthrough.md; do ... mv "$_sidecar" .tasks/archive/ ...; done
```

`close` moves task, yaml, and plan/tr/walkthrough sidecars, but the Spec
(`.specs/{ts}_*.md`, linked via the `**Spec**` header) is left in place —
orphaned. `abandon` (`task.sh:1050-1066`) moves only the task + yaml, **not**
the plan/tr/walkthrough sidecars at all (only `tidy` moves those,
`task.sh:1033-1048`). The three archive paths (`close`, `abandon`, `tidy`) each
implement a different idea of what gets archived.

### F9 — `close` ingests checklist from a root `task.md` that usually doesn't exist

```bash
# task.sh:938 (close) → sync_task_to_internal
# task.sh:347
if [ ! -f "task.md" ] || [ ! -f "$internal_file" ]; then return 0; fi
```

`sync_task_to_internal` silently no-ops when root `task.md` is absent — which is
the norm under the "direct markdown" architecture. Meanwhile `unmount_task`
**deletes** root `task.md`, `protocol.md`, `implementation_plan.md`,
`commit.draft` etc. on unmount/close (`task.sh:88-90`). The "sync human progress
back to internal" step is a dead path in the common case, and the unmount sweep
wipes legacy artifacts any tooling might still read.

### F10 — PCRE `grep -oP` throughout the monolith (GNU-only)

`grep -oP '^\*\*?Phase\*\*?:\s*\K\d+'` appears in `check_phase_transition`
(`task.sh:408`), `list_tasks` (`task.sh:218`), the forgery check
(`task.sh:1156`), etc. BSD/macOS grep has no `-P`/`\K`; on non-GNU systems
phase extraction silently returns empty and the arithmetic guards
(`$((current_phase + 1))`) degrade or throw. Fragile even on Linux across
grep variants.

---

## 3. Severity Ranking

| # | Finding | Impact | Fix |
|---|---|---|---|
| F1 | graduate's ritual unsigned | fresh task fails validate | add `"(State Verified)"` to graduate's `log_ritual` |
| F2 | sync-docs leaves stale rituals | task un-validatable after objective change | prune rituals > target phase on reset |
| F3 | GATE 2 greps task only, message says task *or* spec | approval in spec never unlocks | grep both files |
| F4 | `visibility_interlock` gate flag not in `swt.json` → silently defaults to `True` | hidden gate the user never opted into; no inverse flag | declare the flag (or remove the fallback) |
| F5 | yolo skips guards but validate enforces | mode inconsistency | let validate honor mode |
| F6 | two competing state writers | silent content loss on transitions | single writer (pick twin or sed) |
| F7 | 30 s vs 60 s staleness thresholds | sensor/gate disagree | unify threshold |
| F8 | close/abandon orphan the Spec | archive incompleteness | move Spec with task |
| F9 | sync_task_to_internal dead path | checklist sync no-op | remove or gate on real task.md |
| F10 | `grep -oP` portability | phase parsing breaks on BSD grep | use `sed -E` or python |

---

## 4. Bottom Line

The transition machine is not broken end-to-end, but it is **internally
inconsistent**: the validator's breadcrumb invariants are stricter than what the
transition commands produce. The two highest-severity defects (F1, F2) are
self-inflicted — the toolchain rejects states it created itself. Everything
below that is a family of drift hazards (two writers, three archive paths, two
thresholds, two enforcement modes) that compound in real sessions.

For the ai-dev-toolkit: this **reinforces** keeping the new skills stateless and
decoupled (the "docked, not welded" strategy). Nothing here should block
copying `skills/swt-*` into SWT — it also means the skills should never invoke
`/swt:flow phase|validate|sync-docs|close` as part of their own workflow.