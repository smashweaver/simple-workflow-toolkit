---
name: "swt:commit"
description: Use when writing commit messages, creating commits, or when the user asks about commit message format. Follows a diff-first workflow: staged changes are captured to a `commit.diff` file, the agent drafts a message and saves it to `commit.draft`, the user fine-tunes, then the agent commits and cleans up both files on approval. Enforces a structured, impact-focused commit message format.
user-invocable: true
allowed-tools:
  - Bash
  - Read
---

# /swt:commit — Commit Message Guidelines

Clear, impact-focused commit messages make code history readable and maintainable. These guidelines help you write messages that explain _why_ a change matters, not just _what_ changed.

---

## 🛑 Protocol Audit Ritual (MANDATORY)

Before drafting any commit message, the agent MUST output the following audit signature to prove compliance:

> **Protocol Audit**:
> - [x] Re-read `swt:commit/SKILL.md`
> - [x] Task state validated (`skills/swt-task/scripts/task.sh validate <file>`)
> - [x] Checked for red flags (no dots/slashes in bullets, no jargon)
> - [x] Verified Phase 8 (Review & Refine) is closed

> [!CAUTION]
> **Zero Tolerance for Structural Noise**: Bullets MUST focus on outcomes. Any mention of file paths, extensions, or internal refactoring details is a protocol failure.

---

## Diff-First Workflow

> 🛑 **Gate 5 Rule (The Finality Loop)**: A commit is the absolute final act of a task. You MUST NOT proceed with `/swt:commit` until Phase 8 (Review & Refine) is fully verified and explicitly closed by the user. If the user asks for a commit prematurely, remind them to complete Phase 8 first.

This skill follows a **diff-first, draft-and-approve** commit process. The user stages only the relevant changes, exports the diff, and lets the agent draft and store a commit message — then approves before the agent executes the commit and cleans up.

Two temporary files are used, both gitignored:
- **`commit.diff`** — the staged diff exported from git
- **`commit.draft`** — the agent-drafted commit message, ready to edit
- **`commit.task`** — the agent-tracked task reference (Closes: .tasks/...)

### Step 1 — Stage your changes
Selectively stage only the files and hunks relevant to this commit:
```bash
git add <file>          # stage a specific file
git add -p              # interactively stage hunks
git status              # verify what is staged
```

### Step 2 — Capture the staged diff
Export the staged diff to a temporary file in the project root:
```bash
git diff --cached > commit.diff
```

### Step 3 — Invoke the commit skill
Ask the agent to draft a commit message:
> *"Generate a commit message for the diff in `commit.diff`"*

The agent will:
1. **Re-read this `SKILL.md` file** — always refresh your understanding of these specific commit guidelines before drafting.
2. **Execute Protocol Audit Ritual** — output the audit signature at the start of your response.
3. **Read `commit.diff`** — never run `git diff` directly; always read from the file.
4. **Scan for active tasks** — search for `.tasks/*.md` files in the **current directory**, **parent directory**, and any **sub-project directories** to understand the active work context and align terminology.
5. **Execute Task Validation** — run `bash skills/swt-task/scripts/task.sh validate <task_file>` to ensure Phases 5–7 are marked as complete. If validation fails, STOP and fix the task file before drafting.
6. **Consult `AGENTS.md`** — read both the project-level and parent-level `AGENTS.md` for strategic goals and conventions.
7. **Analyze the changes** — identify what changed, why, and the impact.
8. **Draft a commit message** — following the format and principles below. Store the message in `commit.draft`.
9. **Agent Self-Correction Pass** — Before finalizing, the agent MUST review the draft against the "Agent Self-Correction Guardrails" above. There is no automated linting; this is a mandatory manual ritual.
10. **Track task closure** — if an active task was found in Step 4, write the reference to `commit.task`: `Closes: .tasks/YYYYMMDDHHMMSS_slug.md`. STRICTLY separate this metadata from the `commit.draft` message.
11. **Display the draft** — show the contents of `commit.draft` and `commit.task` for review. Let the user know the mapped task will be auto-closed.

> ⚠️ **The agent MUST NOT execute any `git commit` command at this stage.**

The `commit.draft` file format:
```
<type>(<scope>): <short, descriptive summary>

* <bullet: user benefit or impact>
* <bullet: additional distinct information>
```

### Step 4 — Fine-tune (Contextual Iteration)
The draft can be revised until it is perfect. The user may **edit `commit.draft` directly** in their editor, or **ask the agent to make specific changes**.

For every agent revision request, the agent will:

1.  **Read `commit.draft`** — Capture and preserve any manual edits made in the editor first.
2.  **Re-analyze `commit.diff`** — Verify the technical accuracy of the requested change against the actual diff.
3.  **Re-scan active tasks** — Re-check `.tasks/` in the current, parent, and sub-project directories for updated context.
4.  **Ask Probing Questions** — If a requested change contradicts the technical diff or task state, the agent MUST ask for clarification before updating. For example:
    - *"The diff shows a new file was added, but you're asking to frame this as a fix — can you clarify the intent?"*
    - *"This bullet conflicts with what's in the diff — did I misread a deletion?"*
5.  **Update in-place** — Overwrite `commit.draft` with the refined version and display the result.

Common fine-tuning actions:
- Swap the type or scope
- Sharpen a bullet point to focus on **impact** over implementation
- Remove a bullet that restates the title
- Reorder bullets by impact (most important first)

### Step 5 — Approval Gate (HARD STOP)

> 🚫 **The agent is STRICTLY FORBIDDEN from executing `git commit` unless the user gives explicit approval. No exceptions.**

After displaying or updating the draft, the agent MUST present this exact binary choice:

---
**Ready to commit?**
- **Apply** — I'll run `git commit -F commit.draft` to apply this message.
- **Fine-tune** — Edit `commit.draft` manually in your editor, or tell me what to change.
---

The agent waits for the user's response before taking any further action.

### Step 6 — Commit (agent-executed on "Apply")
Only on explicit "Apply" confirmation, the agent runs:
```bash
git commit -F commit.draft
```

### Step 7 — Post-Commit Task Auto-Close
Immediately after a successful commit:
1. Inspect the `commit.task` file for a `Closes: .tasks/...` directive.
2. If found, retrieve the newly created commit hash using: `git rev-parse HEAD`
3. Execute the `/swt:task close` operation on the linked task file:
   - Change `**Status**` to `done`
   - Change `**Completed**` to today's date
   - Prepend the commit hash and a brief description under `## Commit Reference`.

### Step 8 — Cleanup (agent-executed)
After the commit and task updates are complete, delete both temp files:
```bash
rm commit.diff commit.draft commit.task
```

> **Tip:** Add both files to `.gitignore` so they are never accidentally staged:
> ```bash
> echo -e "commit.diff\ncommit.draft\ncommit.task" >> .gitignore
> ```

---

## Quality Checklist & Agent Guardrails

### Agent Self-Correction Guardrails

> [!IMPORTANT]
> Agents MUST run this check before presenting any `commit.draft` to the user. If any red flags are found, the agent MUST self-correct and update the draft.

| Red Flag | Reason | Correction |
|---|---|---|
| Bullet starts with `-` | Violates syntax convention | Use `*` for all bullets |
| Bullet contains `/` or `.` | Likely a file or directory reference | Focus on **behavioral outcomes** and **intent** |
| Bullet repeats scope | Redundancy | Remove the repetition; focus on impact |
| Bullet contains jargon | Too technical | Replace with natural language outcome |
| Bullet describes structure | Implementation noise | Remove; focus on the behavior/benefit enabled by that structure |
| Intro paragraph present | Adds noise | Remove; move the primary intent to the commit title |

### Human/Final Verification

Before committing, verify:

- [ ] Would someone understand the **impact** without knowing implementation?
- [ ] Can I remove any bullet that just restates the title?
- [ ] Am I describing a **problem solved** or steps taken?
- [ ] Am I focusing on the **intent and effect** of the change, not just implementation details?
- [ ] Does each bullet add **new information** (no duplication)?
- [ ] Are benefits **specific and measurable** (not vague)?
- [ ] Is my scope **as specific as possible** without being overly narrow?
- [ ] Does my scope accurately reflect the **primary functional area** changed?

---

## Format

```
<type>(<scope>): <short, descriptive summary>
```

Optional detailed bullets (if applicable):

* What users gain from the change
* How the change improves user experience
* What problems it solves or prevents
* Performance or architectural improvements

## Types

Use one of these types:

- `feat` — New feature or functionality
- `fix` — Bug fix
- `chore` — Minor UI/wording/text cleanups
- `refactor` — Code restructuring without behavior changes
- `test` — Test additions or modifications
- `docs` — Documentation changes
- `style` — Code style/formatting (no logic changes)
- `perf` — Performance or architectural improvements
- `Initial commit` — Initial commit

## Scope Guidelines

- Scope should be the **most specific functional area** affected by the change
- Prefer narrow, precise scopes over broad ones
- Examples: `payments`, `ui`, `auth`, `reports`, `database`, `scripts`, `routes`, `api`, `models`, `views`, `controllers`
- Use generic `chore` without scope only for repo-level tasks
- **Bad**: `backend` (too broad) - **Good**: `routes`, `api`, `models` (specific)

### Choose Specific Over Broad

- ❌ `backend` — covers too many potential changes
- ✅ `routes` — specifically targets route-related changes
- ✅ `api` — specifically targets API endpoint changes
- ✅ `models` — specifically targets data model changes

### Match Scope to Change Impact

- Single file changes: Use the component/module name (e.g., `routes`, `auth`)
- Multiple related files: Use the broader category (e.g., `api`, `ui`)
- Cross-cutting concerns: Use the technical area (e.g., `performance`, `testing`)

## Writing Principles

- Use natural language, short but expressive
- Focus on **benefits and impact**, not implementation details
- Focus on **intent and effect** — explain what problem you're solving and how the change improves the codebase
- **Conciseness Enforcement**: Combine the commit title and primary intent into a single sentence where possible. Avoid redundant introductory paragraphs that simply restate the title before the bullet points.
- Each bullet point should add distinct information (avoid redundancy)
- **Impact-First Compaction**: Consolidate "implementation vs. interface" details into single, high-impact bullets.
- **Natural Language Preference**: Use natural, expressive language over technical jargon (e.g., "standardize flags" vs "strip prefix string").
- Use bullet points only when there are multiple meaningful changes
- Benefits should be **specific and measurable**, not vague

## Anti-Patterns to Avoid

### Don't repeat the action in title and bullets

```
❌ chore(ui): update button styles
   * Updated button styling to be more consistent

✅ chore(ui): standardize button styling for consistency
   * Buttons now follow brand guidelines across checkout flow
   * Reduces visual confusion for users on mobile devices
```

### Don't list implementation steps, list outcomes

```
❌ refactor(queries): changed N+1 query to use joins
   * Rewrote database query structure

✅ perf(queries): optimize report generation for bulk operations
   * Page load time reduced from 2s to 300ms
   * Queries now execute in single database round trip
```

### Don't echo the scope in bullet points

```
❌ fix(auth): resolve token validation issues
   * Auth now validates tokens correctly

✅ fix(auth): prevent session hijacking with token rotation
   * Users stay logged in securely across sessions
   * Malicious token reuse is now blocked
```

### Don't use redundant bullets

```
❌ * Documentation improvements for clarity
   * Users benefit from clearer documentation

✅ * Users understand API security requirements without confusion
   * New contributors onboard 40% faster with explicit examples
```

### Don't use file references in bullet points

When writing bullet points, focus on behavior, outcomes, and impact rather than pointing to specific files. This applies to all projects, whether the beneficiary is a human user, another developer, or an AI agent/toolkit.

```
✅ * Task rules now discoverable from one place — agents no longer need to cross-reference /swt:flow
   * Buttons now follow brand guidelines across the checkout flow
```

### Don't highlight internal structural details

Avoid mentioning encapsulation, file organization, or internal refactoring unless it has a direct behavioral impact.

```
❌ * skill logic is self-contained within skills/swt-link/ for better encapsulation
   * extracted route listing logic to dedicated service for modularity

✅ * link logic is now fully portable across project environments
   * route listing service enables reusable analysis features
```

## Examples

### Feature with user impact

```bash
git commit -m "feat(cash_reports): restructure Z-Reading with dynamic payment breakdowns" -m "* Users instantly see payment distribution by method
* Report generation 3x faster on large transaction volumes
* New contributors can extend payment types without modifying core logic"
```

### Fix with security benefit

```bash
git commit -m "fix(services): use explicit namespacing to resolve autoload conflicts" -m "* Prevents accidental code execution from naming collisions
* Eliminates hard-to-debug production errors
* Framework updates no longer break existing integrations"
```

### Performance improvement

```bash
git commit -m "perf(queries): batch user lookups to eliminate N+1 queries" -m "* Dashboard API responses drop from 800ms to 120ms
* Database load reduced by 70% during peak usage
* Users experience snappier page interactions"
```

### Documentation clarity

```bash
git commit -m "docs(readme): improve security guidance and reduce confusion" -m "* Users understand file permissions requirements on first read
* Eliminates duplicate security warnings from multiple sections
* New developers complete setup 50% faster with clearer prerequisites"
```

### Chore with maintenance benefit

```bash
git commit -m "chore(scripts): rename install.sh to update-golang.sh for clarity" -m "* Users immediately understand the script manages both installation and updates
* New contributors identify Go-specific tooling 40% faster with explicit naming
* Eliminates ambiguity that could lead to users running wrong scripts
* All documentation examples now match actual filenames—prevents copy-paste errors"
```

### Refactor with precise scope

```bash
git commit -m "refactor(routes): extract route listing logic to dedicated service" -m "* Makes route listing functionality more modular and easier to maintain
* Reduces complexity in main application startup code
* Creates reusable service that can be extended with additional route analysis features"

# Compare with less precise scope:
# ❌ refactor(backend): extract route listing logic to dedicated service
```

### Initial commit

```bash
git commit -m "Initial commit: GraphQL project using Apollo Server and TypeScript" -m "* Ready-to-use Apollo Server setup for immediate development
* TypeScript configuration with proper build setup
* Standard project structure for faster onboarding"
```

## Mandatory Syntax Rules

- Use **one `-m` flag** for the title, **one `-m` flag** for all bullets
- Use actual newlines within the string to separate bullet points
- Use blank lines to visually separate logical sections (if needed)
- Do NOT use `-m ""` for empty lines
- Do not execute the git command — present as a reference for the user to run
