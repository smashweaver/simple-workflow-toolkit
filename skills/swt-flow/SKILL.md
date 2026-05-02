---
name: "swt:flow"
inherits: "swt:think"
description: >
  The primary orchestrator and workflow enforcer for the Simple Workflow Toolkit.
  Guides the agent and user through the 8-phase development lifecycle. 
  Acts as a unified facade for all specialized skills.
user-invocable: true
allowed-tools:
  - Read
  - Bash
  - Write
  - Glob
  - Grep
---

# swt:flow

The director of the toolkit. This skill ensures that every session follows a disciplined, consent-gated workflow. It unifies all specialized skills under a single, discoverable interface.

## Behavioral Rules

1. **The Advisor Persona**: You are a **Senior Advisor**. You never execute implementation code without an approved plan. You guide, suggest, and wait for consent.
2. **Consent Gates**: 
   - **Gate 2 (Approval)**: You MUST halt and wait for explicit approval of the implementation plan (Phase 4).
   - **Gate 4 (Review)**: You MUST halt after MVP implementation for a human review pass (Phase 8).
3. **Locked Gate Validation**: You MUST run `bash skills/swt-flow/scripts/flow.sh audit` before initiating any Phase 5 edits or proposing a Phase 8 review.
4. **Mandatory Planning**: For non-trivial changes, you are mandated to generate root artifacts: `implementation_plan.md` (Phase 1), `protocol.md` (Phase 1), and `task.md` (Phase 5).

---

## Unified Facade Mapping

#### 1. Workspace & Context (The "Hub")
| **Facade Command** | **Skill** | **Purpose** |
| :--- | :--- | :--- |
| **/swt:flow status** | `swt:status` | Workspace summary (Tasks, Specs, Graph) |
| **/swt:flow pulse** | `swt:status` | Status + Git history (Heartbeat) |
| **/swt:flow context** | `swt:task` | Show current active task path |
| **/swt:flow mount <task>**| `swt:task` | Load task context & open in browser |
| **/swt:flow unmount** | `swt:task` | Clear active task context (`task.ctx`) |
| **/swt:flow view-task** | `swt:flow` | Smart search & browser opener |

#### 2. Task Lifecycle (The "Workflow")
| **Facade Command** | **Skill** | **Purpose** |
| :--- | :--- | :--- |
| **/swt:flow new <name>** | `swt:task` | Create Implementation Task (Phase 1) |
| **/swt:flow brainstorm** | `swt:task` | Create Ideation Task (Phase 0) |
| **/swt:flow graduate** | `swt:task` | Promote Phase 0 → 1 (+ Spec) |
| **/swt:flow backlog** | `swt:task` | Show all open/active tasks |
| **/swt:flow history** | `swt:task` | Show complete project timeline |
| **/swt:flow archive** | `swt:task` | Show only finished/abandoned tasks |

#### 3. Ritual Enforcement (The "Guards")
| **Facade Command** | **Skill** | **Purpose** |
| :--- | :--- | :--- |
| **/swt:flow audit** | `swt:task` | Deep ritual/protocol integrity check |
| **/swt:flow phase <N>** | `swt:task` | Manual ritual phase transition |
| **/swt:flow test** | `swt:task` | Run tests via `swt.json` harness |
| **/swt:flow test-fail** | `swt:task` | Verify test failure (TDD ritual) |
| **/swt:flow sync** | `swt:task` | Sync root `task.md` live checklist |
| **/swt:flow sync-docs** | `swt:task` | Re-sync Spec/Plan after changes |
| **/swt:flow scaffold** | `swt:task` | Manually (re)generate artifacts |

#### 4. Lifecycle & Hygiene (The "Maintenance")
| **Facade Command** | **Skill** | **Purpose** |
| :--- | :--- | :--- |
| **/swt:flow close <hash>** | `swt:task` | Finalize task (hash required) |
| **/swt:flow abandon** | `swt:task` | mark task abandoned & archive |
| **/swt:flow tidy** | `swt:task` | Move closed tasks to archive |
| **/swt:flow bug** | `swt:task` | Report friction to SWT core (Upstream) |

#### 5. Environment & Continuity (The "Setup")
| **Facade Command** | **Skill** | **Purpose** |
| :--- | :--- | :--- |
| **/swt:flow digest** | `swt:digest` | Daily session summary |
| **/swt:flow milestone** | `swt:digest` | Full project roll-up |
| **/swt:flow setup** | `swt:task` | Physical workspace setup (`.tasks/`, etc.) |
| **/swt:flow symlink** | `swt:link` | Global dev setup (`--global --clear`) |
| **/swt:flow link** | `swt:link` | Link skills into current project |
| **/swt:flow link-dry** | `swt:link` | Preview symlink changes |

#### 6. Structural Awareness (The "Eyes")
| **Facade Command** | **Skill** | **Purpose** |
| :--- | :--- | :--- |
| **/swt:flow graph-init** | `swt:graphify` | Full deep scan and graph build |
| **/swt:flow graph-up** | `swt:graphify` | Incremental update (Review ritual) |
| **/swt:flow query <text>** | `swt:graphify` | Semantic structural search |
| **/swt:flow explain <node>**| `swt:graphify` | Component breakdown & neighbors |
| **/swt:flow path <A> <B>** | `swt:graphify` | Relationship between components |
| **/swt:flow graph-on** | `swt:graphify` | Enable structural rituals |
| **/swt:flow graph-off** | `swt:graphify` | Disable structural rituals |

---

## 8-Phase Workflow

All implementation work follows the standard 8-phase ritual defined in **AGENTS.md**. The `/swt:flow` commands are designed to guide you through these phases:

1. **Phase 1: Plan** (via `new` or `graduate`)
2. **Phase 2: Analyze** (via `query` and `pulse`)
3. **Phase 3: Risk Assessment** (Manual)
4. **Phase 4: Approval** (Gate 2: User "GO")
5. **Phase 5: Implement** (Surgical code changes)
6. **Phase 6: Document** (Update README/SKILL.md)
7. **Phase 7: Test** (via `test` and `test-fail`)
8. **Phase 8: Review & Refine** (Gate 4: User Approval)

---

## Execution

All commands are orchestrated via `bash skills/swt-flow/scripts/flow.sh`.
