# Execution Prompt: Modernize SWT for Modern Agent Discovery & agentskills.io Standards

```markdown
Act as a Principal AI Developer Tooling Architect. Please execute a comprehensive modernization of the Simple Workflow Toolkit (SWT) repository to conform strictly to the latest **agentskills.io** open standard and multi-engine agent discovery specifications (supporting AGY IDE 2.0, Antigravity, OpenCode, Claude Code, and Cursor) while preserving 100% of SWT's dogfooding methodology, Phase 0–3 workflows, loop rituals, and test suites.

---

### Core Objectives
1. **Optimize Token Economics via Progressive Disclosure:** Decompose the 37KB monolithic `AGENTS.md` into modular, high-signal rules in `.agents/rules/` so agents don't consume ~10k tokens on every session turn.
2. **Normalize Skill Manifests:** Update all 16 `SKILL.md` manifests to adhere strictly to the `agentskills.io` standard (kebab-case `name` matching folder names, standardized YAML frontmatter, clear invocation triggers in `description`).
3. **Establish Multi-Engine Parity:** Add standard entry points for OpenCode (`.opencode/instructions.md`), Claude Code (`CLAUDE.md`), and AGY/Antigravity (`.agents/rules/` & `.agents/skills/`).
4. **Eliminate Directory Redundancy:** Consolidate `skills/` and `.agents/skills/` into a single canonical source of truth to ensure zero-drift dogfooding.
5. **Preserve Backward Compatibility & Pass Audits:** Ensure `./scripts/audit.sh` and existing verification test suites pass completely.

---

### Step-by-Step Execution Plan

#### Step 1: Decompose Monolithic Rules into `.agents/rules/`
Create the `.agents/rules/` directory and modularize the contents of `AGENTS.md` into focused, domain-specific rule files:

1. **`.agents/rules/swt-session-lifecycle.md`:**
   - Session-start protocol (reading `.digests/`, orienting workspace, detecting sub-projects).
   - Task lifecycle states (`TODO`, `DOING`, `BLOCKED`, `DONE`, `PARKED`) and `.tasks/` directory conventions.
2. **`.agents/rules/swt-methodology.md`:**
   - The 4-Phase execution lifecycle:
     - Phase 0: Brainstorm & Scenario Ideation (A/B/C).
     - Phase 1: Planning & Spec Drafting (`.specs/`).
     - Phase 2: Surgical Code Execution & Verification.
     - Phase 3: Session Digest & Commit Workflow (`.digests/`, `commit.draft`).
3. **`.agents/rules/swt-loop-rituals.md`:**
   - Invariants from `LOOPS.md` (Self-correcting feedback loops, anti-hallucination guardrails, audit triggers).
4. **`.agents/rules/specification-guardrail.md`:**
   - Ground-truth protection for `.specs/`, PRDs, RFCs, and architecture docs.
5. **Lean Root `AGENTS.md`:**
   - Refactor the root `AGENTS.md` into a lean (<100 lines) index summarizing SWT and pointing explicitly to `.agents/rules/*.md` and `.agents/skills/` for legacy compatibility.

---

#### Step 2: Normalize All 16 Skill Manifests to `agentskills.io`
Iterate across all skill folders in `.agents/skills/`:
- `swt-audit`, `swt-code`, `swt-commit`, `swt-datastar`, `swt-devkit`, `swt-digest`
- `swt-flow`, `swt-graphify`, `swt-init`, `swt-link`, `swt-mermaid`, `swt-prd`
- `swt-spec`, `swt-status`, `swt-task`, `swt-think`

For each `SKILL.md`:
- Change `name: "swt:<action>"` to standard kebab-case `name: swt-<action>` (matching the folder name).
- Ensure user slash command triggers (e.g. `/swt:init`, `/swt:flow`, `/swt:think`) remain prominently documented in the `description:` frontmatter string and markdown body so models trigger on both natural language and slash commands.
- Verify YAML frontmatter syntax validity.

---

#### Step 3: Configure Cross-Engine Entry Points
1. **`.opencode/instructions.md`:**
   - Create instructions routing OpenCode agents to `.agents/rules/` for declarative invariants and `.agents/skills/` for procedural skills.
2. **`CLAUDE.md`:**
   - Update to reference `.agents/rules/` and `.agents/skills/` alongside `AGENTS.md`.
3. **`GEMINI.md`:**
   - Update to point cleanly to `.agents/rules/` and the modernized workspace structure.

---

#### Step 4: Consolidate Skills Directory
- Ensure `.agents/skills/` is the single authoritative source of truth for all skills.
- Replace the root `skills/` folder with a relative symlink (`skills -> .agents/skills`) or automated export mechanism so changes in `.agents/skills/` are instantly reflected across the entire repo without manual copying.

---

#### Step 5: Verification & Audit
1. Run the SWT structural audit script:
   ```bash
   ./scripts/audit.sh
   # or python3 scripts/audit.py
   ```
2. Verify all references in `swt-skills-audit.json`, `ARCHITECTURE.md`, and `README.md` match the updated structure.
3. Validate that all 16 skills are discoverable, valid, and contain no broken relative links.

---

Please execute these changes cleanly, maintaining all of SWT's existing behavioral integrity and dogfooding ergonomics.
```
