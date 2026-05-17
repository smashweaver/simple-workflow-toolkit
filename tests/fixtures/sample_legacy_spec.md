# Spec: Markdown-to-HTML Migration Engine (Unified HTML Ecosystem)
**Version**: 1.0
**Status**: approved
**Linked Task**: [20260517230649_build-legacy-markdown-to-yaml-migration-converter.md](file:///home/jason/tools/swt/.tasks/20260517230649_build-legacy-markdown-to-yaml-migration-converter.md)

## 1. Problem Statement
The Simple Workflow Toolkit (SWT) currently stores tasks, specs, and digests as pure Markdown files (`.md`). While human-readable, managing their state, checkboxes, phase transitions, and ritual log histories inside Python requires brittle, regex-based AST text parsing that is highly vulnerable to syntax corruptions and formatting drift.

Rather than moving to a separate YAML database + HTML compiled cache layer (which introduces heavy caching and compilation overhead in a `.cache/` directory), we want to pivot to a **Unified HTML Ecosystem**. In this ecosystem, every task/spec/digest file on disk is stored directly as a visual, self-contained **Rich HTML file** (`.html`). It serves a dual-nature role:
1. **For Humans**: A premium, CSS-styled, dark-mode visual web dashboard.
2. **For AI/Orchestrator**: A precise JSON database embedded inside a `<script id="swt-metadata" type="application/json">` block at the bottom of the page.

To achieve this transition, we need a robust, test-driven Markdown-to-HTML migration converter engine.

## 2. Goals
- **Markdown AST Extraction**: Build a robust Python parser in `twin.py` that reads legacy Markdown tasks, specs, and digests and extracts their metadata, objectives, checklist items, and log histories into a Python dictionary structure.
- **Visual HTML Generation**: Implement a premium, self-contained HTML renderer that takes the extracted state dictionary and generates a gorgeous CSS dashboard (Outfit Google font, glassmorphism card layouts, custom status/phase badges, and styled checkbox listings).
- **Embedded JSON State Serialization**: Embed the exact structured state dictionary inside a `<script id="swt-metadata" type="application/json">` tag at the bottom of the HTML page.
- **100% Robust Re-hydration**: Implement a Python utility that safely extracts and parses the JSON block back from the HTML page, guaranteeing 100% data fidelity.
- **Automated Verification Harness**: Establish a complete Python unit test suite (`tests/test_migrate.py`) to validate 100% round-trip conversion and state-sync robustness.

## 3. Proposed Solution
The converter utility will be built directly inside `twin.py` (which contains the current GlobalTwin logic) to preserve class context and utility access.

## 4. User Stories
- **US-001**: As a developer, I can double-click any migrated task `.html` file inside `.tasks/` or `.digests/` and view its status, description, and logs natively in any web browser without needing to run any compiler or local server.
- **US-002**: As an AI agent, I can load a task's visual HTML file, parse its embedded JSON block in under 5ms, make surgical updates, re-render it, and save it back without ever risking Markdown AST parsing errors.

## 5. Non-Functional Requirements
- **Zero Caching**: No cache directory or intermediate files. The visual asset on disk *is* the source of truth database.
- **Performance**: Metadata extraction from HTML files must complete in `<10ms` in Python.
- **Git Compatibility**: The JSON script block inside the HTML must be cleanly formatted with line-breaks so that git diffs show clean, single-line updates for checklists and logs.

## 6. Implementation Plan
1. **Core Parser**: Implement standard Markdown AST ingestion inside `twin.py` using the `GlobalTwin` framework.
2. **HTML Templating & Styling**: Design and embed the standard visual HTML template with premium inline CSS styles in `twin.py`.
3. **HTML Serializer & JSON Embedder**: Implement the compilation logic that marries the state dictionary into the visual template and JSON block.
4. **JSON Re-hydration Engine**: Build the ultra-fast HTML-embedded JSON extractor.
5. **CLI Utility Routing**: Add simple command-line arguments to `twin.py` to allow file-to-file conversion (e.g. `twin.py --convert <input.md> <output.html>`).
6. **Unit Tests**: Implement `tests/test_migrate.py` asserting multiple round-trips, checklist checkmark transitions, and 100% data fidelity.

## 7. Risks & Mitigations
- **Risk**: Manual human text edits to the HTML visual DOM getting lost if the AI regenerates the page.
- **Mitigation**: We parse custom user sections into a dedicated `notes` key in the JSON metadata. The template automatically renders the `notes` block beautifully in the visual DOM during re-generation, preserving all custom developer commentary exactly.

## 8. Success Criteria
- Standalone CLI command successfully converts tasks, specs, and digests from Markdown to Rich HTML.
- Converted HTML pages contain valid, cleanly formatted JSON script blocks.
- Converted HTML files render as beautiful, styled dashboards in standard web browsers.
- `tests/test_migrate.py` passes all verification runs under the test harness.

## 9. Out of Scope
- Modifying orchestrator shell commands (`task.sh`, `flow.sh`) to natively read HTML task data (deferred to Task 3).
- Purging `.agents/` and `.claude/` directories from the active workspace during setup (deferred to Task 2).

## 10. Open Questions
- *None.* All technical feasibility risks and re-hydration patterns were successfully resolved during the isolated Proof of Concept (`.cache/poc_html_sync.py`).

## 11. References
- [.cache/poc_html_sync.py](file:///home/jason/tools/swt/.cache/poc_html_sync.py) (Working Proof of Concept).
- [AGENTS.md](file:///home/jason/tools/swt/AGENTS.md) (SWT Methodology).

## 12. MVP Definition
- Direct MD-to-HTML conversion engine integrated inside `twin.py`.
- Flawless re-hydration API validated by Python unittest suites.
- Command-line interface ready to be invoked by Task 2's upgrade script.

## Objective
Build a robust, highly reliable MD-to-HTML migration parser and serializer inside `twin.py` that ingests legacy Markdown tasks, specs, and digests and converts them to valid Rich HTML files with embedded JSON state with 100% data fidelity.

## Notes
* **Implementation sequence**:
  1. **Task 1 (This Task)**: Build MD-to-HTML converter engine in Python.
  2. **Task 2**: Build setup/upgrade facade, clean drift, arm hooks, and trigger Task 1's HTML converter.
  3. **Task 3**: Migrate orchestrator shell commands and hooks to natively read and write HTML task databases.


## A. Markdown Parser Logic
Leverage python string parsing and regex boundaries to ingest a standard Markdown file:
* **Metadata Extraction**: Parse keys like `**Status**`, `**Phase**`, `**Priority**`, `**Category**` inside the header section.
* **Objective/Sections**: Extract sections under headers like `## Objective` or `## Summary`.
* **Checklists**: Parse standard checkbox rows (e.g. `- [x]`, `- [/]`, `- [ ]`) and map them to checklist arrays with text and checked statuses.
* **Ritual Logs**: Collect `<!-- RITUAL: ... -->` comments.

## B. HTML Serialization Template
A built-in HTML template containing fully inline, highly refined CSS:
* **Styling**: Google Font Outfit, deep slate backgrounds (`#0b0f19`), glassmorphism cards, purple accent bars (`#8b5cf6`), and styled checkbox items matching checked (`✓`), partial (`⚡`), and unchecked (` `) states.
* **Embedded Database**: Rendered pretty-printed JSON at the bottom:
  ```html
  <script id="swt-metadata" type="application/json">
  {
    "meta": { "Task": "...", "Status": "...", "Phase": 0 },
    "sections": { "Objective": "..." },
    "checklists": { "Checklist": [...] }
  }
  </script>
  ```

## C. State Re-hydration
The parser function `extract_metadata_from_html(html_path)` will use simple, ultra-fast, and completely robust string splits to extract the string content between `<script id="swt-metadata" type="application/json">` and `</script>` tags and safely parse it with `json.loads`.
