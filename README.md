# Simple Workflow Toolkit (SWT)

A reusable Claude Code skill that enforces a structured 8-phase development workflow for agentic coding agents. Ensures agents act as advisors and co-pilots rather than autonomous coders.

## Overview

This project provides a **Claude Code skill** (`/swt:flow`) that embeds disciplined software development practices directly into any AI coding session. The skill is based on the methodology in `AGENTS.md` and enforces: planning, analysis, risk assessment, approval gates, careful implementation, documentation, testing, and iterative development.

## Quick Start

### Install into a project

```bash
# Standard install (copies files)
./scripts/install-skill.sh /path/to/project

# Link install (creates symlinks — recommended for development)
./scripts/install-skill.sh --link /path/to/project
```

### Use in a Claude Code session

Once installed, the skill is available via:

- **Explicit invocation**: Run `/swt:flow` and describe what you want to build.
- **Auto-trigger**: Describe a non-trivial task — the skill's description will activate it automatically.

The skill walks you through 8 phases: plan, analyze, risk assess, approve, implement, document, test, and iterate.

## Workflow Phases

| Phase | Purpose |
|---|---|
| **1. Plan** | Gather context, map dependencies, propose a detailed step-by-step plan |
| **2. Analyze** | Assess impact on components, state, performance, and contracts |
| **3. Risk Assessment** | Identify risks (security, performance, state, compatibility) with mitigations |
| **4. Approval** | Present the complete plan — do not proceed without explicit user approval |
| **5. Implement** | Provide code snippets or precise edits, one file at a time, with explanations |
| **6. Document** | Update docs, diagrams (Mermaid), and generate commit messages |
| **7. Test** | Run existing test suites or provide manual verification checklists |
| **8. Iterative Development** | Verify MVP works, then refactor for maintainability and SOLID principles |

## Project Structure

```
swt/
├── skills/
│   ├── swt-flow/           # Structured 8-phase development process
│   │   └── scripts/
│   │       └── swt.sh      # Universal AI Task Manager
│   ├── swt-task/           # Task lifecycle: naming, creation, graduation, status
│   ├── swt-init/           # Workspace bootstrap (scaffolds AGENTS.md)
│   │   └── templates/      # single, workspace
│   ├── swt-spec/           # Idea-to-specification (SPEC.md / PRD generation)
│   ├── swt-code/           # Behavioral guidelines (surgical changes, simplicity)
│   ├── swt-commit/         # Diff-first, draft-and-approve commit workflow
│   ├── swt-digest/           # Automated session summaries for continuity
│   └── swt-mermaid/        # Mermaid diagram syntax rules
├── scripts/
│   └── install-skill.sh    # Installs skills into any project
└── AGENTS.md               # Source methodology document (Source of Truth)
```

## Skills Suite

| Skill | Trigger | Purpose |
|---|---|---|
| **Init** | `/swt:init` | Bootstraps `AGENTS.md` for any new workspace. Runs once, before any tasks or specs begin. |
| **Task** | `/swt:task` | Owns the full task lifecycle — naming validation, creation, graduation, status updates, and filtered listing. |
| **Workflow** | `/swt:flow` | Enforces planning, analysis, and approval gates. |
| **Spec** | `/swt:spec` | Transforms ideas and brainstorms into a structured `SPEC.md` (PRD). Bridges Phase 0 ideation to Phase 1 planning. |
| **Coding** | `/swt:code` | Ensures surgical edits and minimal, simple code. |
| **Commit** | `/swt:commit` | Manages disciplined, impact-focused commit history. |
| **Digest** | `/swt:digest` | Automates session summaries with multi-digest recursive continuity. |
| **Mermaid** | `/swt:mermaid` | Prevents parse errors in documentation diagrams. |

## Quick Start

### 1. Install into a project

We recommend setting `SWT_HOME` in your `.bashrc` or `.profile` for easy symlinking:

```bash
export SWT_HOME="$HOME/tools/swt"
```

Then run the install script:

```bash
# For a single project
./scripts/install-skill.sh --link /path/to/project

# Global install (recommended)
./scripts/install-skill.sh --link ~/.claude
```

### 2. Use in a Claude Code session

Once installed, use the commands directly or describe tasks that trigger them:

- **Planning**: Run `/swt:flow` for non-trivial changes.
- **Committing**: Capture a diff to `commit.diff`, then follow the `/swt:commit` flow.
- **Status/Resume**: Ask *"whats up?"* or *"where am I?"* to trigger a disciplined context restoration.

## What Makes This Different

Unlike a traditional linter, this suite operates at the **agent behavior level**. It defines the boundaries of AI collaboration, ensuring the agent remains a **Senior Advisor and Co-pilot** while the user maintains final oversight and execution control.

## Methodology

The `AGENTS.md` file contains the full source methodology, including detailed pre-implementation checklists, execution boundary rules, and best practices.

## License

MIT

## Development

### Adding a new skill
1. Create a new directory in `skills/swt-<name>`.
2. Add a `SKILL.md` following the standard template.
3. Add any necessary scripts in the skill's `scripts/` directory.
4. Update the `Skills Suite` table in the root `README.md`.
5. Link the skill for local testing: `./scripts/install-skill.sh --link /path/to/test-project`.
