# Tactical Roadmap: Refactor swt:flow unmount command
**Spec**: .specs/20260502103548_refactor-swt-flow-unmount-command.md

> This is an ephemeral execution protocol. It provides the tactical roadmap for implementation and ensures ritual compliance. 
> **Mandatory Cleanup**: This file must be deleted before finalizing the task.

## 1. Mission Briefing
Refactor the SWT task context management to prioritize `mount` and `unmount` verbs across all scripts and documentation. Implement soft deprecation for the legacy `ctx` commands to improve CLI symmetry and agent intuition.

## 2. Gate 3: Execution Loop (Tactical Chunks)
Break the implementation into 3-5 logical chunks. Pause and perform a **Locked Gate Ritual** after each chunk.

* [x] **Chunk 1**: Update `task.sh` with `mount`/`unmount` commands and `ctx` deprecation warnings
* [x] **Chunk 2**: Update `flow.sh` routing table and help text to include `mount`/`unmount`
* [x] **Chunk 3**: Synchronize `SKILLS.md`, `AGENTS.md`, and `README.md` with the new command terminology

## 3. Commit Discipline Gut Check (MANDATORY)
Before initiating `/swt:flow commit`, you MUST perform a self-audit against these guidelines. **Failure to follow these will result in a Protocol Breach.**

### Audit Signature (Proof of Compliance)
Copy and paste this into your session output before drafting:

> **Protocol Audit**:
> - [x] Re-read `swt:commit/SKILL.md`
> - [x] Task state validated (`task.sh validate <file>`)
> - [x] Checked for red flags (no dots/slashes in bullets, no jargon)
> - [x] Verified Phase 8 (Review & Refine) is closed
> - [x] Verified **Repo Hygiene** (no leftover trash/temp files)

### Formatting Guardrails
- [ ] **Title Format**: MUST follow `<type>(<scope>): <summary>` (e.g., `feat(ui): add button`).
- [ ] **Zero Structural Noise**: NO dots (`.`), slashes (`/`), or file extensions in bullets. Focus on **impact**.
- [ ] **Bullet Syntax**: Use `*` for all bullets (NOT `-`).
- [ ] **Punctuation Discipline**: No terminal periods at the end of the summary or bullet points.
- [ ] **Visual Structure**: Mandatory empty line between the header and the first bullet point.
- [ ] **Formatting Pass**: Perform an explicit self-correction pass on the draft before presenting it to the user.

## 4. Finality Ritual
1. Verify Phase 8 (Review & Refine) is complete.
2. Run `git add .` and verify staged changes.
3. Initiate the `/swt:flow commit` ritual.
