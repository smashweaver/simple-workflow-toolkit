# Tactical Roadmap: {{Task Title}}
**Spec**: {{Spec File}}

> This is an ephemeral execution protocol. It provides the tactical roadmap for implementation and ensures ritual compliance. 
> **Mandatory Cleanup**: This file must be deleted before finalizing the task.

## 1. Mission Briefing
[Summarize the current execution goal and desired outcome]

## 2. Gate 3: Execution Loop (Tactical Chunks)
Break the implementation into 3-5 logical chunks. Pause and perform a **Locked Gate Ritual** after each chunk.

- [ ] **Chunk 1**: [Description]
- [ ] **Chunk 2**: [Description]
- [ ] **Chunk 3**: [Description]
- [ ] **Chunk 4**: [Description]
- [ ] **Chunk 5**: [Description]

## 3. Commit Discipline Gut Check (MANDATORY)
Before initiating `/swt:flow commit`, you MUST perform the **Double-Pass Drafting** ritual. **Failure to follow these will result in a Protocol Breach.**

### The Double-Pass Ritual
1. **Pass 1 (The Technical Draft)**: Generate a technical summary of the changes based on the diff and task state.
2. **Ritual Intermission**: Re-read `swt:commit/SKILL.md`.
3. **Pass 2 (The Impact Refactor)**: Sanitized the draft into impact-focused bullets.
   - **Zero Structural Noise**: Remove all file names, extensions, and directory paths.
   - **Zero Jargon**: Replace technical commands and internal toolkit names with natural language outcomes.
   - **User Benefit**: Focus on what the user or the developer team gains from this change.

### Audit Signature (Proof of Compliance)
Copy and paste this into your session output before drafting:

> **Protocol Audit**:
> - [ ] Re-read `swt:commit/SKILL.md`
> - [ ] Task state validated (`task.sh validate <file>`)
> - [ ] Checked for red flags (no dots/slashes in bullets, no jargon)
> - [ ] Verified Phase 8 (Review & Refine) is closed
> - [ ] Verified **Repo Hygiene** (no leftover trash/temp files)

### Formatting Guardrails
- [ ] **Title Format**: MUST follow `<type>(<scope>): <summary>` (e.g., `feat(ui): add button`).
- [ ] **Zero Structural Noise**: NO dots (`.`), slashes (`/`), or file extensions in bullets. Focus on **impact**.
- [ ] **Bullet Syntax**: Use `*` for all bullets (NOT `-`).
- [ ] **Punctuation Discipline**: No terminal periods at the end of the summary or bullet points.
- [ ] **Visual Structure**: Mandatory empty line between the header and the first bullet point.

## 4. Finality Ritual
1. Verify Phase 8 (Review & Refine) is complete.
2. Run `git add .` and verify staged changes.
3. Initiate the `/swt:flow commit` ritual.
