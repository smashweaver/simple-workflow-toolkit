# Simple Workflow Toolkit (SWT)

A disciplined AI coding toolkit that keeps agents as advisors — not autonomous coders. Install it once and every session follows a structured plan-approve-implement workflow.

→ **[See SKILLS.md](./SKILLS.md)** for the full Skills Catalog and usage guide.

## Quick Start

### Install

We recommend setting `SWT_HOME` in your `.bashrc` or `.profile`:

```bash
export SWT_HOME="$HOME/tools/swt"
```

Then link the skills into your project or globally using the orchestrator:

```bash
# Setup the project (.tasks, .specs, etc.)
/swt:flow setup

# Install physical copies (Stable Mode)
/swt:flow install --global

# Link skills into current project (Dev Mode)
/swt:flow link
```

### Use in a session

Once installed, invoke the orchestrator to guide your session:

- **Plan a feature**: `/swt:flow new "Feature Name"`
- **Show backlog**: `/swt:flow backlog`
- **Check pulse**: `/swt:flow pulse` (Status + Git)
- **Commit changes**: `/swt:flow commit`
- **Set context**: `/swt:flow mount <task>`
- **End session**: Say "goodbye" to trigger `/swt:flow digest`

## Project Structure

```
swt/
├── skills/
│   ├── swt-think/          # Base behavioral guidelines
│   ├── swt-flow/           # Unified Facade & Orchestrator
│   ├── swt-task/           # Task Manager (backlog, history, archive)
│   ├── swt-status/         # Project state & heartbeat (pulse)
│   ├── swt-init/           # Workspace bootstrap (AGENTS.md)
│   ├── swt-link/           # Skill linker (setup, symlink)
│   ├── swt-spec/           # Idea-to-specification (SPEC.md)
│   ├── swt-code/           # Surgical coding guidelines
│   ├── swt-graphify/       # Structural awareness (query, explain, path)
│   ├── swt-commit/         # Diff-first, draft-and-approve workflow
│   ├── swt-digest/         # Automated session summaries (milestone)
│   ├── swt-mermaid/        # Mermaid diagram syntax guard
│   └── swt-audit/          # Structural health & workspace auditor
├── SKILLS.md               # Full Skills Catalog (usage guide)
├── ARCHITECTURE.md         # Structural Manifest (inheritance & patterns)
└── AGENTS.md               # Internal development protocol (dogfooding)
```

## What Makes This Different

Unlike a traditional linter, this suite operates at the **agent behavior level**. It defines the boundaries of AI collaboration through a **Recursive State Machine**, ensuring the agent remains a **Senior Advisor and Co-pilot** while the user maintains final oversight and execution control. 

Every session follows a structured plan-approve-implement workflow that explicitly models the "Light Bulb" iteration loop. These loops are physically baked into the **`swt-flow`** orchestrator to prevent agent drift and "loop jumping."

→ **[See skills/swt-flow/SKILL.md](./skills/swt-flow/SKILL.md)** for the full recursive methodology.

## Architecture & Inheritance

SWT follows a strict inheritance model where all skills derive from the **swt:think** base layer. The ecosystem is unified by the **swt:flow** orchestrator, which acts as a developer-aligned facade for all toolkit operations.

→ **[See ARCHITECTURE.md](./ARCHITECTURE.md)** for structural diagrams and design rationale.

## Structural Awareness (Recommended)

SWT integrates with the **graphify** engine to provide a "Big Picture" view of your project.

1.  **Initialize**: Run `/swt:flow graph-init` to map your project.
2.  **Analyze (Phase 2)**: Run `/swt:flow query "<your question>"` to identify risks.
3.  **Review (Phase 8)**: Run `/swt:flow graph-up` to see a "Structural Diff" of your changes.

To use these features, ensure the engine is installed: `pip install graphifyy`.

## Feedback Loop: Bug Reporting

While using SWT in any project, report toolkit friction directly back to the core backlog. Run `/swt:flow bug` to create a task in `$SWT_HOME/.tasks/` that captures what happened.

- **Trigger**: `/swt:flow bug`
- **Context captured**: Current project path, active task, and current phase
- **Destination**: A brainstorm task in `$SWT_HOME/.tasks/` for SWT maintainers

No manual navigation needed — the friction point becomes an actionable task for the toolkit developers.

## License

MIT

## Development

### Upgrading / Refreshing SWT Locally

When developing the toolkit or when you want to apply the latest stable versions of all 12 skills locally in this repository:

```bash
# Refresh active skills in this repo's discovery paths (.agents/ and .claude/)
bash skills/swt-flow/scripts/flow.sh install
```

### Upgrading a Consumer Project

To push the latest skills and upgrades to any project folder that consumes SWT:

```bash
# Copy latest stable skills to the target project directory
bash skills/swt-flow/scripts/flow.sh install "/path/to/your/project"

# Or within the target project's context, run a setup upgrade:
/swt:flow setup --upgrade
```

### Running Tests

To verify that the toolkit's parsing logic, AST compiler, state transition engines, and hygiene constraints are fully correct, run our unified unit and integration test suite:

```bash
uv run python3 -m unittest discover -s tests
```
