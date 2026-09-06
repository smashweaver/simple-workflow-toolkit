---
name: "swt:datastar"
inherits: "swt:think"
description: >
  Use when the user wants to set up or install the Datastar design system into
  a project. This is the implementation layer of the build pipeline — it
  provides CSS design tokens, component styles, and reusable HTML patterns for
  Datastar hypermedia apps. Trigger whenever the user says things like "set up
  the design system", "install the Datastar skill", "drop in the CSS and
  components", or when implementation of a DESIGN.md is about to begin. Runs
  scripts/install.sh to copy static/ and templates/ into the project, then
  instructs the agent to follow resources/AGENTS.md and
  resources/DATASTAR_PATTERNS.md.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# /swt:datastar — Design System + Components for Datastar Apps

You are the design-system provider for the SWT build pipeline. You install a
drop-in design system — CSS design tokens, component styles, and reusable HTML
patterns — for building Datastar hypermedia apps with polished UI.

## What You Provide

| Resource | Purpose |
|---|---|
| `resources/static/css/tokens.css` | Complete design token system (colors, spacing, type, motion, dark mode) |
| `resources/static/css/components.css` | Component styles (buttons, inputs, cards, tables, nav, alerts) |
| `resources/templates/components/*.html` | Copy-paste HTML component patterns |
| `resources/templates/layouts/base.html` | Full app shell with sidebar, header, toast container |
| `resources/templates/pages/dashboard.html` | Sample page composing all components |
| `resources/AGENTS.md` | Agent contract — how to build in the project |
| `resources/DATASTAR_PATTERNS.md` | Curated Datastar API reference |

## Core Principles

1. **Tokens only** — Every visual value is a CSS custom property. No hardcoded values anywhere.
2. **Semantic classes** — `.btn`, `.input`, `.card`, `.stack`, `.row`, `.container`. Not `.p-4` or `.text-lg`.
3. **Dark mode built-in** — Automatic via `prefers-color-scheme`. Zero extra work.
4. **Accessible by default** — Native HTML elements, proper ARIA, keyboard navigation, focus states.
5. **Zero JavaScript** — All interactivity is declarative via Datastar attributes.
6. **DESIGN.md wins** — If a `DESIGN.md` exists in the project root, its tokens override the defaults.

---

## Workflow

1. **Install the assets** — run:
   ```bash
   bash skills/swt-datastar/scripts/install.sh [target_path] [--force]
   ```
   (Omit `target_path` to install into the current directory. `--force` overwrites existing files.)

2. **Link the CSS** — instruct the user to add to their base layout:
   ```html
   <link rel="stylesheet" href="/static/css/tokens.css">
   <link rel="stylesheet" href="/static/css/components.css">
   ```

3. **Apply DESIGN.md (if present)** — if a `DESIGN.md` exists in the project root, convert its values into `tokens.css` custom properties:
   - Extract color palette → CSS custom properties
   - Extract typography scale → font-size/line-height/weight variables
   - Extract spacing scale → margin/padding variables
   - Extract radii → border-radius variables
   - Extract shadows → box-shadow variables
   - Map component styles to CSS classes
   - Generate dark mode variant if specified

4. **Brief the agent** — tell it to read `AGENTS.md` and `DATASTAR_PATTERNS.md` before writing any markup:
   > "Read AGENTS.md and DATASTAR_PATTERNS.md before writing any code. Follow the design system rules exactly. Only use CSS custom properties from tokens.css. No Tailwind. No custom JavaScript."

---

## Design System Hierarchy

When a DESIGN.md (e.g. from awesome-design-md) is present:

```
1. DESIGN.md            ← PRIMARY visual source (convert to tokens.css)
2. designer-skills      ← VALIDATION layer (.agents/designer-skills/, optional)
3. tokens.css + components.css  ← IMPLEMENTATION layer (this skill)
```

If DESIGN.md conflicts with Datastar defaults, DESIGN.md wins.

## Anti-Patterns (NEVER DO)

- ❌ Hardcode colors, spacing, or font sizes in component CSS — always use tokens
- ❌ Use `$` or `$$` magic functions (removed in Datastar V1)
- ❌ Manually toggle loading spinners — use `data-indicator`
- ❌ Use double underscores in signal names (reserved for modifiers)
- ❌ Write custom JavaScript for interactivity
- ❌ Use Tailwind or other utility-first CSS frameworks

---

## Companion Skills

- **`swt:devkit`** — upstream: generates `AGENTS.md`/`WIREFRAMES.md` referencing this design system, and produces the `AI_PROMPT.md` used to build with these components.

This skill **inherits from `swt:think`** (`skills/swt-think/SKILL.md`), which provides base behavioral principles for all AI agent reasoning.