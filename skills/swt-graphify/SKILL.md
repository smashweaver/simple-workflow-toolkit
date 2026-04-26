---
name: "swt:graphify"
description: >
  Enhances project navigation and dependency mapping using knowledge graphs.
  Integrates with swt:flow to provide structural awareness during Phase 2 (Analyze).
user-invocable: true
allowed-tools:
  - Bash
  - Read
---

# /swt:graphify — Structural Awareness Skill

This skill acts as an orchestrator for `graphify` (https://github.com/safishamsi/graphify). It provides structural awareness to the SWT workflow by bridging the gap between deterministic scripts and semantic markdown tasks.

## Discovery Ritual (MANDATORY)

Before execution, `/swt:graphify` must locate its engine:
1. **Local Skill**: Check `./skills/graphify/SKILL.md`.
2. **Global Skill**: Check `~/.agents/skills/graphify/SKILL.md`.
3. **CLI Binary**: Verify `graphify` is reachable via `uv tool run` or `$PATH`.

If no skill is found but the binary is present, `/swt:graphify` will default to the standard CLI commands.

## Integration with SWT Flow
... (rest of the sections remain the same)

| Phase | Usage |
|---|---|
| **Phase 2: Analyze** | Run `graphify query` to identify "Affected Concepts" across the workspace. |
| **Phase 8: Refine** | Run `graphify update` to see how the implementation changed the project's structural graph. |
| **Status / Digest** | Reference the `GRAPH_REPORT.md` for "God Nodes" and "Surprising Connections". |

## Core Commands

- `/swt:graphify init` -> `uv tool run --from graphifyy graphify .` (Full build)
- `/swt:graphify update` -> `uv tool run --from graphifyy graphify update .` (Incremental)
- `/swt:graphify query "<question>"` -> Query the knowledge graph.
- `/swt:graphify explain "<node>"` -> Plain-language explanation of a concept and its neighbors.

## Protocol for Phase 2 (Analyze)

When analyzing a proposed change:
1.  **Check for Graph**: If `graphify-out/graph.json` exists, you MUST query it before falling back to `grep`.
2.  **Identify Bridges**: Look for nodes that connect different communities (e.g., a shared utility used by both frontend and backend).
3.  **Audit Rationale**: Read the "Design Rationale" extracted by `graphify` to understand *why* a connection exists.

## Protocol for Phase 8 (Review & Refine)

After implementation:
1.  Run `/swt:graphify update`.
2.  Observe the **Graph Diff**. Did you introduce unexpected dependencies? Did you simplify a "God Node"?
3.  Report these structural insights to the user during the Refinement Loop.

---

## Execution Layer

Always use `uv tool run --from graphifyy graphify` to ensure the correct version is used.
If the graph does not exist, suggest running `/swt:graphify init` to build it.
