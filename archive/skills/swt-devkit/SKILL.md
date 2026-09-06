---
name: "swt:devkit"
inherits: "swt:think"
description: >
  Use when the user has a PRD.md and wants it turned into build documents for
  an AI coding agent. This is the implementation-planning layer of the build
  pipeline. Trigger whenever the user says things like "generate wireframes",
  "create a test plan", "make the build prompts", "set up AGENTS.md", or when
  a PRD.md (from swt:prd) exists and implementation planning is about to begin.
  Produces four outputs in the project: WIREFRAMES.md, TEST_PLAN.md,
  AI_PROMPT.md, and AGENTS.md. Optionally integrates a DESIGN.md (brand design
  system, e.g. from awesome-design-md) and designer-skills workflows
  (.agents/designer-skills/). Use it proactively after a PRD is ready and the
  user signals intent to build.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# /swt:devkit — PRD to Build Documents

You are the implementation-planning engine of the SWT build pipeline. You turn
a completed `PRD.md` into everything an AI coding agent needs to build the app.

**Prerequisite:** A `PRD.md` exists in the project root or `docs/` (produced by
`swt:prd`). If no PRD exists, stop and offer to run `swt:prd` first.

## Core Principles

1. **One PRD in → five build documents out.** Always produce all outputs — never cherry-pick.
2. **Reference the exact template structures** in `resources/templates/`. Don't invent output formats.
3. **DESIGN.md wins.** If a `DESIGN.md` exists in the project root, it is the PRIMARY visual source; all wireframes and prompts must reference its tokens.
4. **Stateless.** Write outputs to the project root / `docs/`. Do not touch `.tasks/`, `.specs/`, `task.ctx`, or any SWT transition state.
5. **Specific > fluffy.** Every test maps to a TEST-XXX ID. Every phase has concrete tasks.

---

## The Five Outputs

### 1. WIREFRAMES.md — Screen structures
- Generated from PRD Section 6 (Page Flows) and Section 7 (UI/UX).
- Text-based component composition per screen (`.card`, `.stack`, `.row`), Datastar attributes, responsive notes.
- **If DESIGN.md exists**, reference its tokens for colors/type/spacing.
- Structure: `resources/templates/WIREFRAME_TEMPLATE.md`.

### 2. TEST_PLAN.md — Executable test cases
- Generated from PRD Section 4 (User Stories) and Section 9 (Security).
- Every user story → 1–3 test scenarios in Given/When/Then format, mapped to TEST-XXX IDs.
- Covers: unit, integration, security, performance. Priority: P0/P1/P2.
- Structure: `resources/templates/TEST_PLAN_TEMPLATE.md`.

### 3. AI_PROMPT.md — Copy-paste build prompts
- Generated from PRD Section 12 (MVP Scope) and Section 11 (Tech Stack).
- One prompt per development phase, plus system prompt and iteration templates (bug fix, feature add, refactor).
- **If DESIGN.md exists**, add DESIGN.md to the context references and system rules.
- Structure: `resources/templates/AI_PROMPT_TEMPLATE.md`.

### 4. AGENTS.md — Project rules
- Generated from PRD Sections 9 (Security), 10 (Performance), 11 (Tech Stack), 7 (UI/UX).
- Tech stack constraints, file organization, design system hierarchy, anti-patterns.
- **If DESIGN.md exists**, encode "DESIGN.md is PRIMARY visual source" as the top rule.
- Structure: `resources/templates/AGENTS_TEMPLATE.md`.

### 5. DESIGN.md integration
- **If DESIGN.md exists** (e.g. copied from awesome-design-md): validate that wireframes reference its tokens, add "follow DESIGN.md" rules to AGENTS.md, add it to AI prompt context.
- **If no DESIGN.md exists**: generate a basic one from PRD Section 7, and note that it's a fallback (swt:datastar provides the implementation tokens).

---

## Optional Pre-Steps

### Brand design (recommended)
If the user wants a real brand look, fetch a `DESIGN.md`:

```bash
git clone https://github.com/VoltAgent/awesome-design-md.git /tmp/awesome-design-md
cp /tmp/awesome-design-md/linear/DESIGN.md ./DESIGN.md
```

Mood guide: Linear/Notion → professional, calm · Stripe/Vercel → modern, developer-focused · Figma/Airbnb → warm, friendly · Slack/Intercom → clean, SaaS.

### Designer skills (optional)
Fetch validation workflows:

```bash
chmod +x skills/swt-devkit/scripts/fetch-designer-skills.sh
./skills/swt-devkit/scripts/fetch-designer-skills.sh
```

Creates `.agents/designer-skills/` in the current directory. If present, DevKit references these workflows for accessibility checks and critiques.

---

## Design System Hierarchy

When DESIGN.md exists, follow this priority:

```
1. DESIGN.md (awesome-design-md)     ← PRIMARY visual source
2. designer-skills (.agents/)        ← VALIDATION layer
3. Datastar skill (tokens.css)       ← IMPLEMENTATION layer
```

If DESIGN.md conflicts with Datastar defaults, DESIGN.md wins.

---

## Output Location

Write all outputs to the project root, or `docs/` if a `docs/` folder exists:

```
your-project/
├── DESIGN.md              ← optional, from awesome-design-md
├── AGENTS.md              ← output (project rules)
├── docs/
│   ├── PRD.md             ← input (from swt:prd)
│   ├── WIREFRAMES.md      ← output 1
│   ├── TEST_PLAN.md       ← output 2
│   └── AI_PROMPT.md       ← output 3
├── .agents/designer-skills/  ← optional, from fetch-designer-skills.sh
└── [your code]
```

---

## Workflow

1. **Read inputs**: `PRD.md` (required), `DESIGN.md` (if present), `.agents/designer-skills/` (if present).
2. **Read templates**: the four files in `resources/templates/`.
3. **Generate all four outputs** following the template structures exactly.
4. **If DESIGN.md exists**, integrate it into all outputs (tokens, rules, context).
5. **Summarize in chat**: what was generated, where, and what the user should do next (run `swt:datastar` for the design system, then build with `AI_PROMPT.md`).

---

## Quality Checklist

Before presenting the outputs, verify:

- [ ] All four documents written to disk (never only chat)
- [ ] WIREFRAMES.md covers every screen named in PRD Section 7
- [ ] TEST_PLAN.md has TEST-XXX IDs for every user story
- [ ] AI_PROMPT.md has one prompt per MVP phase
- [ ] AGENTS.md encodes security rules from PRD Section 9
- [ ] DESIGN.md (if present) is referenced in all outputs
- [ ] No placeholders like `{{...}}` left in generated files

---

## Companion Skills

- **`swt:prd`** — upstream: produces the required `PRD.md`.
- **`swt:datastar`** — downstream: installs the CSS + HTML design system that implements DESIGN.md.

This skill **inherits from `swt:think`** (`skills/swt-think/SKILL.md`), which provides base behavioral principles for all AI agent reasoning.