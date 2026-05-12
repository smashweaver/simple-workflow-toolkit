# SWT Iteration Loops

The Simple Workflow Toolkit (SWT) is built on several nested iteration cycles and "Gate" protocols that ensure alignment and prevent architectural drift. This document visualizes these loops and their relationship to the 8-phase development lifecycle.

## 🌀 Loop Visualization

```mermaid
stateDiagram-v2
    direction TD

    state "Phase 0: Ideate" as P0
    state "Phase 1: Plan" as P1
    state "Phase 2: Analyze" as P2
    state "Phase 3: Risk" as P3
    state "Phase 4: Approval" as P4
    state "Phase 5: Implement" as P5
    state "Phase 6: Document" as P6
    state "Phase 7: Test" as P7
    state "Phase 8: Refine" as P8

    state "Gate 1: Alignment" as G1
    state "Gate 2: Architecture" as G2
    state "Gate 3: Execution" as G3
    state "Gate 4: Refinement" as G4
    state "Gate 5: Finality" as G5

    [*] --> P0: Orientation Protocol

    %% The Brainstorm Loop
    P0 --> P0: Brainstorm Loop
    P0 --> G1
    G1 --> P1

    %% The Planning & Analysis Loops
    P1 --> P1: Planning Loop
    P1 --> P2
    P2 --> P3: Analysis Loop
    P3 --> P2: Analysis Loop
    P3 --> G2

    %% The Execution Loop
    G2 --> P4
    P4 --> P5
    P5 --> G3
    G3 --> P5: Execution Loop
    G3 --> P6
    P6 --> P7

    %% The Light Bulb Iteration Loop (Reset)
    P5 --> P1: Light Bulb Loop (Reset)
    P6 --> P1: Light Bulb Loop (Reset)
    P7 --> P1: Light Bulb Loop (Reset)

    %% The Refinement Loop
    P7 --> G4
    G4 --> P8: Refinement Loop
    P8 --> G4: Refinement Loop

    %% The Commit Loop
    P8 --> G5
    G5 --> G5: Self-Correction Loop (Linting)
    G5 --> [*]: Task Closed

    note right of P0
        Senior Advisor Persona
        No code edits allowed
    end note

    note right of P1
        Scaffold Spec/Plan
        Set Doc Targets
    end note

    note right of G2
        HARD STOP
        User Architecture Approval
    end note

    note right of G5
        Draft-and-Approve
        Zero-Leeway Hygiene
    end note
```

---

## 📖 Loop Definitions

### 1. Orientation Protocol ([*] → P0)
Every new session begins with this recovery cycle. The agent runs `/swt:flow status` to aggregate the latest digests and tasks, reads `task.ctx` to find the active context, and automatically opens relevant docs for the user.

### 2. Brainstorm Loop (Phase 0)
The ideation cycle where the agent acts as a **Senior Advisor**. It requires a Scenario A/B/C trade-off analysis (Discipline vs. Automation vs. Enforcement) before the user provides the "Go" to graduate to implementation.

### 3. Planning & Analysis Loops (Phases 1–3)
*   **Planning Loop**: Artifact generation (`implementation_plan.md`, `protocol.md`) and identifying documentation targets.
*   **Analysis Loop**: Assessing the impact on components, state management, performance, and API contracts.
*   **Gate 2 (The Architecture Loop)**: A **HARD STOP** where the technical approach must be approved by the user.

### 4. Execution Loop (Phases 5–7)
The implementation cycle where surgical edits are made. It is governed by the `protocol.md` (Tactical Roadmap) and `task.md` (Live Checklist). Automated tests are run via `swt.sh test` to provide physical evidence of correctness.

> 📊 **Tactical Visibility**: To ensure **HITL-friendly automation**, the `protocol.md` roadmap is automatically surfaced in the `/swt:flow status` report. Agents are mandated to run a status check after every tactical chunk update to verify alignment with the user.

### 5. Light Bulb Iteration Loop (Reset Mechanism)
A critical "Fail-Safe" that triggers if requirements or understanding change mid-implementation.
1.  **Update Task**: Log new ideas.
2.  **Sync-Downstream**: Automatically update Spec and Plan.
3.  **Mandatory Reset**: Physically resets the task to Phase 1, forcing a re-approval at Gate 2.

### 6. Refinement Loop (Phase 8)
Occurs after the MVP is verified. The task enters a "Polishing" cycle at **Gate 4** where the user can append fine-tuning items or UI tweaks. The loop continues until the user explicitly initiates the closure sequence.

### 7. The Commit Loop (Gate 5)
The finality sequence governing the move from code to history.
*   **Draft-and-Approve**: The agent drafts `commit.draft` and `commit.task`.
*   **Self-Correction Loop**: The draft is passed through a hard shell gate (`lint.sh`). If it fails (e.g., contains file paths or jargon), the agent must autonomously self-correct (up to 3 attempts).
*   **Zero-Leeway Hygiene**: Upon approval, the task is closed, and all ephemeral artifacts are physically purged from the workspace.

### 8. The Global Twin Protocol (Internal State Loop)
A foundational technical cycle that runs inside every programmatic document update. It ensures that the agent never "forgets" manual human edits or implementation progress.
1.  **Harvest**: Extract current document content into JSON.
2.  **Modify State**: Update metadata and checklists in memory.
3.  **Synthesize**: Re-project the document from state using standard templates.

