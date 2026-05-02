# Simple Workflow Toolkit (SWT)

A disciplined AI coding toolkit that keeps agents as advisors — not autonomous coders. Install it once and every session follows a structured plan-approve-implement workflow.

→ **[See SKILLS.md](./SKILLS.md)** for the full Skills Catalog and usage guide.

## Quick Start

### Install

We recommend setting `SWT_HOME` in your `.bashrc` or `.profile`:

```bash
export SWT_HOME="$HOME/tools/swt"
```

Then link the skills into your project or globally:

```bash
# Single project
./scripts/install-skill.sh --link /path/to/project

# Global install (all agents)
./scripts/install-skill.sh --link ~/.claude
```

### Use in a session

Once installed, invoke skills directly or describe your task to trigger them:

- **Plan a feature**: `/swt:flow`
- **Commit changes**: `/swt:commit`
- **Set task context**: `/swt:flow mount <file>`
- **Check task status**: Ask *"whats up?"* or *"where am I?"*
- **End a session**: Say *"goodbye"* to trigger `/swt:digest`

## Project Structure

```
swt/
├── skills/
│   ├── swt-think/          # Base behavioral guidelines for all reasoning tasks
│   ├── swt-flow/           # Structured 8-phase development process
│   ├── swt-task/           # Task lifecycle: naming, creation, graduation, status
│   │   └── scripts/
│   │       └── task.sh     # Task Manager CLI
│   ├── swt-status/         # Aggregates project state for session restoration
│   ├── swt-init/           # Workspace bootstrap (scaffolds AGENTS.md)
│   ├── swt-link/           # Universal skill linker (dogfooding/install)
│   │   └── scripts/
│   │       └── link.sh     # Skill linker backend
│   ├── swt-spec/           # Idea-to-specification (SPEC.md / PRD generation)
│   ├── swt-code/           # Behavioral guidelines (surgical changes, simplicity)
│   ├── swt-graphify/       # Structural awareness and dependency mapping
│   ├── swt-commit/         # Diff-first, draft-and-approve commit workflow
│   ├── swt-digest/         # Automated session summaries for continuity
│   └── swt-mermaid/        # Mermaid diagram syntax rules
├── scripts/
│   └── install-skill.sh    # Installs skills into any project
├── SKILLS.md               # Full Skills Catalog (usage guide)
└── AGENTS.md               # Internal development protocol (dogfooding)
```

## What Makes This Different

Unlike a traditional linter, this suite operates at the **agent behavior level**. It defines the boundaries of AI collaboration, ensuring the agent remains a **Senior Advisor and Co-pilot** while the user maintains final oversight and execution control.

## Methodology

The `AGENTS.md` file contains the full internal development protocol, including the 8-phase workflow, 5 mandatory consent gates, and Locked Gate enforcement logic.

## Structural Awareness (Recommended)

SWT integrates with the **graphify** engine to provide a "Big Picture" view of your project. This prevents architectural drift and surfaces hidden risks.

1.  **Initialize**: Run `/swt:graphify init` to map your project.
2.  **Analyze (Phase 2)**: The agent queries the graph to see how your changes affect "God Nodes" (central dependencies).
3.  **Review (Phase 8)**: Run `/swt:graphify update` to see a "Structural Diff" of your changes in `graphify-out/graph.html`.

To use these features, ensure the engine is installed: `pip install graphifyy`.

## Feedback Loop: Uplink to SWT Core

While using SWT in any project, report toolkit friction directly to the SWT core backlog. Say *"uplink this"* or *"report this to SWT"* to create a task in `$SWT_HOME/.tasks/` that captures what happened.

- **Trigger**: User prompt — "uplink this", "report this to SWT", etc.
- **Context captured**: Current project path, active task, and current phase
- **Destination**: A brainstorm task in `$SWT_HOME/.tasks/` for SWT maintainers to review

No manual navigation to the SWT repo needed — the friction point becomes actionable feedback.

## License

MIT

## Development

### Adding a new skill

1. Create a new directory in `skills/swt-<name>`.
2. Add a `SKILL.md` following the standard template.
3. Add any scripts in the skill's `scripts/` directory.
4. Update `Project Structure` in `README.md` and the Skills Catalog in `SKILLS.md`.
5. Link for local testing: `/swt:link`.

### Multi-Agent Dogfooding

```bash
/swt:link              # Link skills locally
/swt:link --global     # Link skills globally
/swt:link /path        # Link into a specific directory
```
