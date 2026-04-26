---
name: "swt:graphify"
description: >
  Thin wrapper and orchestrator for the graphify engine (safishamsi/graphify).
  Enforces structural awareness rituals during the Analyze (Phase 2) and Review (Phase 8) phases of the SWT workflow.
user-invocable: true
allowed-tools:
  - Bash
  - Read
---

# /swt:graphify — Structural Awareness Skill

This skill acts as a **thin wrapper and orchestrator** for the `graphify` engine (https://github.com/safishamsi/graphify). Its primary role is to bridge the gap between the standalone Python analyzer and the **Simple Workflow Toolkit (SWT)** rituals.

## Nature of this Skill

Unlike other skills that contain complex custom scripts, `swt:graphify` is designed to:
1. **Orchestrate**: Map SWT workflow phases to specific `graphify` commands.
2. **Enforce**: Mandate "Structural Awareness" checks for agents during Phase 2 and Phase 8.
3. **Verify**: Ensure the `graphify` engine is present in the system `$PATH`. (Auto-installation is disabled).

## Discovery Ritual (MANDATORY)

Before execution, `/swt:graphify` must locate its engine:
1. **CLI Binary**: Verify `graphify` is reachable via `$PATH`.

If the binary is missing, `/swt:graphify` will report an error and provide installation instructions.

| Phase | Usage |
|---|---|
| **Phase 2: Analyze** | If enabled, run `swt:graphify query` to identify "Affected Concepts". |
| **Phase 8: Refine** | If enabled, run `swt:graphify update` to see structural changes. |
| **Status / Digest** | Reports state (enabled/disabled) and artifact presence. |

## Core Commands

- `/swt:graphify verify` -> Check if the `graphify` engine is installed in the system.
- `/swt:graphify uninstall` -> Full cleanup: removes artifacts and states.
- `/swt:graphify on | off` -> Explicitly enable/disable structural rituals.
- `/swt:graphify status` -> Check current state, engine presence, and artifact presence.
- `/swt:graphify init` -> Perform a full project build (deep scan).
- `/swt:graphify update` -> Incremental update of the graph.
- `/swt:graphify query "<question>"` -> Semantic search of the codebase.
- `/swt:graphify explain "<node>"` -> Structural breakdown of a component.

## Protocol for Phase 2 (Analyze)

When analyzing a proposed change:
1.  **Check State**: Run `/swt:graphify status`. If **Status: enabled**, proceed to query.
2.  **Query Graph**: If enabled, you MUST query the graph before falling back to `grep`.
3.  **Identify Bridges**: Look for nodes that connect different communities.

## Protocol for Phase 8 (Review & Refine)

After implementation:
1.  **Check State**: If **Status: enabled**, run `/swt:graphify update`.
2.  **Observe Diff**: Report any new "God Nodes" or unexpected coupling.

---

## Execution Layer

All commands are orchestrated via `bash skills/swt-graphify/scripts/graphify.sh`.
If the engine is missing, run `pip install graphifyy` to install it manually.
