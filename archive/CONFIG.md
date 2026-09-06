# SWT Configuration Reference (swt.json)

The `swt.json` file is the central harness for project-specific workflow enforcement. It defines how the toolkit interacts with your code and which "Hard Shell" rituals are active.

## Core Fields

### `mode`
Defines the overall enforcement level.
*   `protocol` (Default): Standard SWT behavior. Enforces sequential phases, mandatory artifacts, and ritual logs.
*   `yolo`: Experimental mode. Bypasses most hard-shell checks (e.g., phase sequentiality, ritual logs). **Not recommended for production/high-stakes tasks.**

### `test_command`
The "Golden Verification" command.
*   **Purpose**: This command is invoked by `/swt:flow test`.
*   **Protocol**: A successful execution must be recorded in the task's `## Ritual Logs` before a commit is authorized in Phase 8.
*   **Example**: `pytest tests/unit`, `npm test`, or `grep -q 'success' output.log`.

## Ritual Gates (`ritual_gates`)

These boolean toggles allow you to customize the intensity of the "Hard Shell" enforcement.

### `ballmer_heartbeat` (Default: `true`)
*   **Effect**: Controls the `PROTOCOL! PROTOCOL! PROTOCOL!` chant output during phase transitions and status checks.
*   **Purpose**: Provides visual confirmation that the protocol-enforcement engine is active.

### `phase_order_enforcement` (Default: `true`)
*   **Effect**: Blocks "Loop Jumping." You cannot transition to a higher phase (e.g., 1 → 5) without logging the intermediate rituals (2, 3, 4).
*   **Purpose**: Prevents methodology drift and ensure thorough planning before execution.

### `hitl_approval` (Default: `true`)
*   **Effect**: Physically blocks implementation (Phase 5) until the string `GATE 2: APPROVED` is found in the task or spec file.
*   **Purpose**: Ensures human-in-the-loop (HITL) sign-off on the technical architecture.

---

## Scaffolding
If `swt.json` is missing, you can generate it using:
```bash
/swt:flow scaffold swt.json <task_file>
```
