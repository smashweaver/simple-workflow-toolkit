# AI Prompt Template — [APP_NAME] Development

> Copy these prompts into your AI coding agent.
> Customize the bracketed sections, then paste and go.
>
> Generated from PRD.md Section 12 (MVP Scope) and Section 11 (Tech Stack).
>
> **If DESIGN.md exists, all prompts should reference it for visual decisions.**

---

## SYSTEM PROMPT (Paste this first)

```
You are an expert full-stack developer building [APP_NAME].

CRITICAL RULES:
1. Read PRD.md before writing ANY code.
2. Read WIREFRAMES.md for screen structures.
3. Read TEST_PLAN.md and implement tests for every [TEST] scenario.
4. Read AGENTS.md for project-wide rules.
5. [If DESIGN.md exists] Read DESIGN.md for ALL visual decisions.
6. [If .agents/designer-skills/ exists] Use those workflows for design validation.

TECH STACK:
- Frontend: [from PRD Section 11]
- Backend: [from PRD Section 11]
- Database: [from PRD Section 11]
- Auth: [from PRD Section 11]
- [Other tech]

DESIGN SYSTEM:
[If DESIGN.md exists]
- Primary visual source: DESIGN.md (from awesome-design-md)
- Colors, typography, spacing, radii from DESIGN.md
- Component styles from DESIGN.md
- Do's and Don'ts from DESIGN.md

[If no DESIGN.md]
- Use Datastar Skill defaults
- Generate basic design system from PRD Section 7
```

---

## PHASE 1: [Phase Name from PRD Section 12]

```
Implement Phase 1 of [APP_NAME] per PRD.md:

[List 3-4 specific tasks from PRD Section 12 Phase 1]

Rules:
- [Tech stack constraints]
- [Design system constraints]
- [If DESIGN.md exists] Use DESIGN.md for all visual decisions
- [Testing requirements]

Follow WIREFRAMES.md for screen structures.
[If DESIGN.md exists] Use DESIGN.md tokens for colors, type, spacing.
Write clean, commented code.
```

---

## PHASE 2: [Phase Name]

```
Implement Phase 2 of [APP_NAME] per PRD.md:

[List tasks from PRD Section 12 Phase 2]

[If DESIGN.md exists] Apply DESIGN.md visual system to all new screens.
[Testing requirements]
```

[Continue for each phase...]

---

## DESIGN INTEGRATION PROMPT

Use this when you need to convert DESIGN.md into implementation:

```
Read DESIGN.md in the project root.
Convert the design system into [CSS/framework] implementation:

1. Extract color palette → CSS custom properties
2. Extract typography scale → font-size, line-height, weight variables
3. Extract spacing scale → margin, padding variables
4. Extract radii → border-radius variables
5. Extract shadows → box-shadow variables
6. Map component styles (button, card, input) to CSS classes
7. Generate dark mode variant if specified

Output: Updated tokens.css and components.css that match DESIGN.md exactly.
```

---

## ITERATION PROMPTS

### Fix a Bug
```
The [feature] is not working correctly.
[Describe the bug].

Expected: [expected behavior]
Actual: [actual behavior]

Fix it while following the rules in AGENTS.md.
[If DESIGN.md exists] Ensure visual fixes follow DESIGN.md.
Write a test that would have caught this bug.
```

### Add a Feature
```
Add [feature] to [APP_NAME].

Requirements:
- [Specific requirement 1]
- [Specific requirement 2]

Reference PRD.md Section [X] for context.
[If DESIGN.md exists] Follow DESIGN.md for visual style.
Follow existing patterns in the codebase.
Update tests accordingly.
```

### Refactor
```
Refactor [component/file] to improve [readability/performance/maintainability].

Constraints:
- Do not change external behavior
- All existing tests must still pass
- Follow AGENTS.md style rules
- [If DESIGN.md exists] Maintain DESIGN.md visual consistency
```

### Design Critique (if designer-skills available)
```
Read .agents/designer-skills/visual-critique/critique-screen.md
Critique the [screen name] in my app.
Identify hierarchy, composition, typography, and color issues.
Provide prioritized fix list.
```
