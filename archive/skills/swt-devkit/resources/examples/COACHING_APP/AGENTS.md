# AGENTS.md — CoachFlow

> This file tells any coding agent how to build in this project.
> Read this file before writing any code.
>
> **DESIGN.md exists in project root — it is the PRIMARY source for visual decisions.**

---

## Tech Stack
- **Frontend:** Datastar (hypermedia, server-rendered HTML + SSE)
- **CSS:** Custom properties (tokens.css + components.css)
- **Backend:** [Go / Python / Node — choose one]
- **Database:** SQLite (MVP) → PostgreSQL (scale)
- **Auth:** Session-based (HTTP-only cookies)
- **Deployment:** [Your platform]

## Project Structure
```
static/css/tokens.css          — Design tokens (from DESIGN.md)
static/css/components.css      — Component styles
static/css/                    — Additional stylesheets
templates/components/          — Reusable HTML partials
templates/layouts/base.html    — Base layout with Datastar script
templates/pages/               — Page-level templates
DESIGN.md                      — Visual design system (from awesome-design-md)
docs/                          — PRD, wireframes, tests, prompts
```

## Design System Hierarchy

1. **DESIGN.md** (from awesome-design-md / Linear) — PRIMARY source
   - Read DESIGN.md before making any visual choice
   - Use exact colors, typography, spacing, radii from DESIGN.md
   - Follow Do's and Don'ts section
   - Preview at design/preview.html to verify

2. **designer-skills** (from .agents/designer-skills/) — VALIDATION layer
   - Run color accessibility checks
   - Validate form interactions
   - Critique screen layouts

3. **Datastar Skill** (tokens.css + components.css) — IMPLEMENTATION layer
   - Convert DESIGN.md values into CSS custom properties
   - Build HTML components matching DESIGN.md specs
   - Add Datastar attributes for interactivity

**Rule:** DESIGN.md overrides all other design sources.

## CSS Rules
- ONLY use CSS custom properties from tokens.css (which reflects DESIGN.md)
- NEVER hardcode colors, spacing, font sizes, or radii
- Use semantic class names: `.btn`, `.input`, `.card`, `.stack`, `.row`, `.container`
- NEVER use Tailwind or utility-first CSS
- Dark mode is automatic via `prefers-color-scheme` in tokens.css

## Datastar Rules
- All interactivity is declarative via `data-*` attributes
- NO custom JavaScript
- Use `data-indicator` for loading states
- Use `__ifmissing` modifier for default signal values
- Use `_` prefix for local-only signals
- Use native HTML elements for accessibility: `<dialog>`, `<details>`, proper `<label>`
- Check `DATASTAR_PATTERNS.md` before using unfamiliar attributes

## Backend Rules
- All API endpoints require authentication (except /login, /register)
- Coaches can only access their own data (coach_id filter on every query)
- All database queries must be parameterized
- All user input must be validated server-side
- All output must be HTML-escaped
- Passwords hashed with bcrypt
- Session cookies: HTTP-only, Secure, SameSite=Strict

## Database Rules
- Use UUIDs for primary keys
- Include created_at and updated_at on every table
- updated_at auto-refreshes on every update
- Foreign keys with ON DELETE CASCADE where appropriate
- Client records are archived, not deleted

## Testing Rules
- Write tests for every TEST-XXX scenario in TEST_PLAN.md
- Unit tests for business logic (payment calc, status checks)
- Integration tests for API endpoints
- Run tests after every feature implementation
- Fix failing tests before moving to next feature

## Anti-Patterns (NEVER DO)
- Hardcoding visual values (use DESIGN.md → tokens.css)
- Using `$` or `$$` magic functions (Datastar V1 removed these)
- Manually toggling loading spinners (use `data-indicator`)
- Double underscores in signal names
- Custom JavaScript for interactivity
- Tailwind or utility CSS
- Client-side routing
- Deleting client records (archive only)
- Returning 403 on wrong coach (return 404 to prevent ID enumeration)
- **Ignoring DESIGN.md when it exists**
