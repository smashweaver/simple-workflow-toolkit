# AGENTS.md

## Thinking (from archived `swt:think` §§1-5 — universals only)

1. Think Before Responding — state assumptions, surface tradeoffs, ask when unclear; never silently fill blanks.
2. Brevity First — minimum output that solves the problem; no speculative sections/abstractions.
3. Focused Responses — touch only what was asked; match existing style; every changed line traces to the request.
4. Clear Success Criteria — transform tasks into verifiable goals; brief plan with `→ verify:` per step; loop until verified.
5. Structural Changes & Manual Consent (HITL) — `git init`, new dir hierarchies, major refactors, destructive ops → HALT, state the gate, WAIT for explicit verbal approval. Auto-approve flags do not satisfy this.

## Coding (from archived `swt:code` §§1-4 — universals only)

1. Think Before Coding — same as above, applied pre-implementation.
2. Simplicity First — minimum code; no speculative features/abstractions/error-handling.
3. Surgical Changes — don't improve adjacent code; clean up only your own orphans.
4. Goal-Driven Execution — tests-first for validation/bugfix/refactor; verifiable goals.

## Session rules

- Be concise.
- Prefer `./archive/` references over inventing prior context.
- For commits, follow `skills/commit/SKILL.md` (Draft-and-Approve) — never naked `git commit -m`.
- Ask before any structural change.

## Archived (do NOT load as behavior)

- `swt:think` §6 Task-First Workflow, companion-skills list, `inherits: none` framing — stays in `archive/skills/swt-think/SKILL.md`.
- `swt:code` Phase 5/7 workflow refs, companion-skill section — stays in `archive/skills/swt-code/SKILL.md`.
- Forward direction: `SWT_FLOW_SEPARATION_IDEATION.md`.
