# AGENTS.md — Datastar Skill

> This file tells any coding agent how to build in this project.
> Read this file before writing any code.

## Tech Stack
- **Framework:** Datastar (hypermedia, server-rendered HTML + SSE)
- **Backend:** [Go + Templ / Python + Jinja / Node + EJS — update as needed]
- **Styling:** Pure CSS custom properties (design tokens). NO Tailwind. NO utility classes.
- **Icons:** Lucide (SVG sprite or inline)
- **Fonts:** System font stack (no external font dependencies)

## Project Structure
```
static/css/tokens.css          — Design tokens (colors, spacing, type, motion)
static/css/components.css      — Component styles (buttons, inputs, cards, layout)
templates/components/          — Reusable HTML partials
templates/layouts/base.html    — Base layout with Datastar script
templates/pages/               — Page-level templates
DATASTAR_PATTERNS.md           — Curated Datastar API patterns for this project
```

## Design System Rules
1. **ONLY use CSS custom properties from `tokens.css`.** Never hardcode hex codes, px values, or font sizes.
2. **Semantic classes only:** `.btn`, `.input`, `.card`, `.stack`, `.row`, `.container`
3. **NO Tailwind.** No `flex`, `p-4`, `text-lg`, etc. Use the token-based component classes.
4. **Dark mode** is handled automatically via `prefers-color-scheme` in `tokens.css`.

## Datastar Rules
1. **Read `DATASTAR_PATTERNS.md` BEFORE using any `data-*` attribute you are unsure about.**
2. **Prefer `data-indicator` for loading states** instead of manually toggling signals.
3. **Use `__ifmissing` modifier** for default signal values.
4. **Use `_` prefix** for local-only signals: `data-signals:_local="value"`.
5. **Use native HTML elements for accessibility:** `<dialog>`, `<details>`, proper `<label>` associations.
6. **NO custom JavaScript.** All interactivity is declarative via Datastar attributes.

## Component Patterns

### Button
```html
<button class="btn btn-md btn-primary" data-on:click="@post('/api/action')">
  Label
</button>
```
Variants: `btn-primary`, `btn-secondary`, `btn-ghost`, `btn-danger`
Sizes: `btn-sm`, `btn-md`, `btn-lg`

### Input
```html
<div class="stack-sm">
  <label for="field" class="label">Label</label>
  <input id="field" class="input" type="text" data-bind="fieldName" />
  <p class="hint" data-show="$fieldError">Error message</p>
</div>
```

### Card
```html
<div class="card">
  <div class="stack">
    <h3 class="card-title">Title</h3>
    <p class="card-text">Content</p>
  </div>
</div>
```

### Modal (Native `<dialog>`)
```html
<dialog id="modal" data-show="$showModal">
  <div class="card modal-card">
    <div class="stack">
      <h3>Title</h3>
      <p>Content</p>
      <div class="row" style="justify-content: flex-end;">
        <button class="btn btn-md btn-ghost" data-on:click="$showModal = false">Cancel</button>
        <button class="btn btn-md btn-primary" data-on:click="@post('/api/confirm')">Confirm</button>
      </div>
    </div>
  </div>
</dialog>
```

### Layout
```html
<div class="container">
  <div class="stack-lg">
    <!-- sections -->
  </div>
</div>
```

## Anti-Patterns (NEVER DO)
- ❌ Hardcode colors, spacing, or font sizes in component CSS
- ❌ Use `$` or `$$` magic functions (removed in Datastar V1)
- ❌ Manually toggle loading spinners — use `data-indicator`
- ❌ Use double underscores in signal names (reserved for modifiers)
- ❌ Write custom JavaScript for interactivity
- ❌ Use Tailwind or other utility-first CSS frameworks
