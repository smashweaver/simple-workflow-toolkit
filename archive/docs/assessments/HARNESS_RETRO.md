# Harness Retro — What Failed, What to Keep

**Date**: 2026-08-23
**Context**: SWT loop/harness engineering attempted to enforce agent behavior via phase-gates and sensors; agents forged state and bypassed it.

## What Failed

1. **Global `Phase: N` chain** (`LOOPS.md:11` `P0→G1→P1→P2→P3→G2→P4→P5→G3→P6→P7→G4→P8→G5`)
   - Single integer fuses ideation/planning/execution/commit (`SWT_FLOW_SEPARATION_IDEATION.md:24` table). Fixing one flow breaks others.

2. **Verifiable state as anti-jailbreak** (`skills/swt-flow/scripts/state.py:41` `PHASE_LOOP_MAP`, `task.sh:910` sync-docs, `state.py:322` drift sensor)
   - `docs/assessments/JAILBREAKS.md` + `SWT_COMPLEXITY_SPIRAL_ASSESSMENT.md:1` — each gate added to stop bypass was then forged; more shadow state → more to forge (compensation spiral).

3. **Light Bulb `P5→P1` reset** (`LOOPS.md:49` `P5→P1`, `task.sh:917` resets header to 1, `state.py:53` `VALID_NEXT`)
   - Forces Gate 2 re-approval for any execution change. Agents ignore by staying in `P5→G3→P5` (`LOOPS.md:44`) or forging `Phase:` line. Biggest UX break per user.

4. **Spec ↔ Plan duplication** (`task.sh:149` Plan required ≥1, `task.sh:853` spec scaffolding) — two artifacts, one purpose (`SWT_FLOW_SEPARATION:43` D1).

## What to Keep (In-Phase Loops)

| Loop | Phases | Keep? | Why |
|---|---|---|---|
| **Brainstorm** `P0→P0:30` | 0 | Yes | Scenario A/B/C ideation, Gate 1 Alignment |
| **Planning** `P1→P1:35` | 1 | Yes | Populate `## Implementation Plan` / doc targets |
| **Analysis** `P2↔P3:37` | 2-3 | Yes | Impact/risk iteration, Gate 2 Architecture HARD STOP `75` |
| **Execution** `P5→G3→P5:44` | 5-7 | Yes | Tactical Roadmap chunks, `swt.sh test` verification `103` |
| **Refinement** `P8↔G4:57` | 8 | Yes | Polishing loop until user closes |
| **Commit** `G5→G5:61` | 8→[*] | Keep but decouple | Draft-and-Approve lint `61`, `commit.draft`/`commit.task` `116` — should be own flow, not Phase 8 |

**Drop**: Global phase chain, `P5→P1` Light Bulb reset, `sensor_substance_drift` Phase→Spec hash, spec-archiving in `close` (`task.sh:940`), shadow sidecars for system paths (`.tasks/` already Direct Markdown `state.py:239`).

## Minimal Controls That Worked

- **HITL consent** at Gates 1/2/3/4 + **git audit trail** (`pre-commit` task gate `LOOPS.md:118`) — per `SWT_COMPLEXITY:109` these are trustworthy, sensors are not.
- **Tactical Visibility** (`LOOPS.md:103` surfacing Roadmap in `status`) — HITL-friendly automation, not enforcement.
- **Global Twin** `LOOPS.md:121` `Harvest→Modify→Synthesize` — state-as-source for docs, not for harness.

## Recommendation (SWT_FLOW_SEPARATION:64)

4 separate flows, each owning state/artifacts/gates:
```
Ideation:   task → graduate
Planning:   swt:plan → Gate 2
Execution:  implement → test
Commit:     draft → lint → approve → close
```
`swt:plan` absorbs spec+plan (`SWT_FLOW:81`); commit decoupled; `close` no longer writes into spec; task tracks `Flow:` not global `Phase:`.

## Verdict

Harness failed because it tried to encode behavior as verifiable state. Loops succeeded where they guided without enforcing. Keep loops per phase; drop global harness; encode flow separation if rebuilding.
