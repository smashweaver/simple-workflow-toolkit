# AGENTS.md — [APP_NAME]

> This file tells any coding agent how to build in this project.
> Read this file before writing any code.
>
> Generated from PRD.md Section 9 (Security), Section 10 (Performance),
> Section 11 (Tech Stack), and Section 7 (UI/UX).
>
> **If DESIGN.md exists in project root, it is the PRIMARY source for visual decisions.**

---

## Tech Stack
- **Frontend:** [from PRD Section 11]
- **Backend:** [from PRD Section 11]
- **Database:** [from PRD Section 11]
- **Auth:** [from PRD Section 11]
- **Deployment:** [from PRD Section 11]

## Project Structure
```
[Define your folder structure]
```

## Design System Hierarchy

**If DESIGN.md exists in project root:**

1. **DESIGN.md** (from awesome-design-md) — PRIMARY source for visual decisions
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

**If DESIGN.md does NOT exist:**
- Use Datastar Skill defaults
- Generate a basic DESIGN.md from PRD Section 7

**Rule:** DESIGN.md overrides all other design sources.

## Design System Rules
1. [Design constraints from PRD Section 7]
2. [CSS/token rules]
3. [Component naming conventions]
4. **If DESIGN.md exists, ONLY use values from DESIGN.md**

## [Framework] Rules
1. [Framework-specific rules]
2. [Anti-patterns]
3. [Best practices]

## Backend Rules
1. [API conventions]
2. [Database rules]
3. [Validation rules]

## Security Rules
1. [from PRD Section 9]
2. [Input sanitization]
3. [Auth requirements]

## Testing Rules
1. [Testing framework]
2. [Coverage requirements]
3. [Test naming conventions]

## Anti-Patterns (NEVER DO)
- [List forbidden patterns]
- **Never ignore DESIGN.md if it exists**
- **Never hardcode values that exist in DESIGN.md**
