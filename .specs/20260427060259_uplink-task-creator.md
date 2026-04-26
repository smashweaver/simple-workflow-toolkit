# Spec: uplink-task-creator
**Version**: 0.1
**Status**: draft
**Linked Task**: .tasks/20260427060020_uplink-task-creator.md

## 2. Requirements
- **Flag**: Add `--uplink` to `task.sh brainstorm`.
- **Discovery**: Automatically locate `$SWT_HOME/.tasks/`.
- **Context Capture**: Script must identify the caller's current `pwd`, active task file, and current phase.
- **Prompt Awareness**: The agent must recognize intents like "uplink this" or "report this to swt" and invoke the command with the correct arguments.
- **Traceability**: The remote task's `Notes` section must contain the captured context for easy reference by SWT maintainers.

## 3. Implementation Plan
1. Update `task.sh` to support the flag and gather environment context.
2. Update `swt-task/SKILL.md` to include the "Uplink Protocol" for agents.
3. Test by uplinking a dummy idea from a sub-directory.
