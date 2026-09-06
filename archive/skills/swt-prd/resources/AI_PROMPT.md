# AI Prompt: Generate Complete PRD

> Copy this prompt, fill in the [BRACKETED] sections with your answers,
> paste into OpenCode / Claude / Cursor, and get a full PRD.

---

```
You are a senior product manager and technical architect. Your job is to
turn a rough app idea into a complete, detailed Product Requirements Document.

Generate a PRD following the exact structure below. Be specific, actionable,
and thorough. Expand brief descriptions into detailed requirements. Invent
reasonable defaults where information is missing.

---

## APP IDEA

**App Name:** [YOUR_APP_NAME]

**What is it?** [1-2 sentences describing the app]

**What problem does it solve?** [1-2 sentences]

**Who is the primary user?** [Be specific: role, situation, pain points]

**Core MUST-HAVE features (3-5):**
1. [Feature 1]
2. [Feature 2]
3. [Feature 3]
4. [Feature 4]
5. [Feature 5]

**Features NOT in first version:**
- [Out of scope 1]
- [Out of scope 2]
- [Out of scope 3]

**Main entities/things in the app:** [e.g., Users, Orders, Products]

**Any special calculations or rules?** [e.g., "Calculate tax based on region"]

**Main user flow:** [e.g., "Login → Dashboard → Create Item → Save → View List"]

**Tech stack preference:** [e.g., "Datastar + Go + SQLite"]

**Design direction:** [e.g., "Clean like Linear, dark mode"]

**How do you know the MVP is done?** [Your definition of done]

---

## OUTPUT FORMAT

Generate a complete PRD.md with these sections:

### 1. Product Overview
- Name, tagline, type, target user, core value

### 2. Goals & Non-Goals
- 3–5 must-have features (Goals)
- 3–5 out-of-scope features (Non-Goals)

### 3. User Personas
- Primary persona (name, description, pain points, current tools, tech comfort)
- Secondary persona (optional)

### 4. User Stories
- Grouped by epic (5–7 epics, 3–5 stories each)
- Format: "As a [persona], I want [action] so that [benefit]"

### 5. Data Model
- 3–6 entities with fields, types, and relationships
- Include created_at and updated_at on every table

### 6. Page Flows
- 3–5 key user flows, step by step

### 7. UI/UX Requirements
- Design direction (mood, reference apps, density)
- Key screens (5–7 screens described)
- Responsive behavior

### 8. Business Logic
- 2–4 calculations, rules, or algorithms
- Write as pseudocode or plain English logic

### 9. Security Requirements
- Auth method, authorization, data protection, input validation

### 10. Performance Requirements
- Page load targets, pagination, search, concurrent users

### 11. Tech Stack
- Table: Frontend | CSS | Backend | Database | Auth | Deployment

### 12. MVP Scope
- 4–5 phases, each with 3–4 tasks
- Time estimate per phase (1 week each)

### 13. Open Questions
- 2–3 unresolved questions about scope or approach

---

## RULES

1. Be SPECIFIC. "Users can search" is bad. "Users can search by name, email, or tag with debounced 300ms input" is good.
2. Write user stories in exact format: "As a [persona], I want [feature] so that [benefit]"
3. Data model must include field types (UUID, string, integer, decimal, timestamp, enum, boolean, text)
4. Every entity needs created_at and updated_at
5. Page flows must be step-by-step, numbered
6. Business logic must be executable pseudocode
7. Tech stack must be realistic for a solo developer
8. MVP phases must be achievable in 1 week each
9. Do not include images, diagrams, or wireframe drawings
10. Output as plain markdown, ready to save as PRD.md
```

---

## Example: Minimal Input

Here's how little you need to write to get a great PRD:

```
App Name: HabitTrack
What is it? A simple habit tracker for people who hate complex apps.
What problem does it solve? Existing habit trackers are bloated with features I don't use.
Who is the primary user? Me. I want to track 3–5 daily habits without friction.
Core features: Add habits, mark complete, streak counter, weekly review
Not in first version: Social features, reminders, categories, data export
Main entities: Habits, Completions
Special rules: Streak resets if missed 2 days in a row
Main flow: Open app → See today's habits → Click to mark done → View streak
Tech stack: Datastar + Python + SQLite
Design: Minimal like a todo app, light mode only
Done when: I can track 5 habits for a week without bugs
```

The AI will expand this into a complete 10KB PRD.

---

## Example: Detailed Input

For a more precise PRD, provide more detail:

```
App Name: CoachFlow
What is it? A practice management tool for independent coaches.
What problem does it solve? Coaches use 4+ tools (Calendar, Sheets, Notes, Stripe). This replaces all of them.
Who is the primary user? Alex, a solo life coach with 15 clients. Uses Calendly and Google Sheets. Forgets follow-ups. Doesn't know who paid.
Core features:
  1. Client database with contact info, coaching focus, status
  2. Session scheduling with conflict detection
  3. Session notes linked to clients
  4. Payment tracking against session packages
  5. Dashboard showing today's sessions and overdue alerts
nNot in first version: Client portal, video calls, email automation, multi-coach, mobile app
Main entities: Coach, Client, Session, Goal, Payment
Special rules:
  - Payment status = sessions_completed vs sessions_paid_for
  - Alert if no session in 14 days
  - Monthly revenue calculation
Main flow: Login → Dashboard → Click Client → Schedule Session → Add Notes → Record Payment
Tech stack: Datastar + Go + SQLite
Design: Clean like Linear/Notion. Sidebar nav. Cards. Tables. Dark mode.
Done when: I can manage 10 clients end-to-end without leaving the app
```

---

## Usage with OpenCode

```bash
# In your project directory:
> /add PRD_BUILDER.md
> [paste the filled-in prompt above]

# The AI generates a complete PRD.md
# Save it, review it, then:
> /add PRD.md
> Implement Phase 1 per PRD.md
```
