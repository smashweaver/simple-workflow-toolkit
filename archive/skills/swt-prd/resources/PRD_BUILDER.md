# PRD Builder Skill

> Turn any app idea into a structured Product Requirements Document.
> Use this yourself, or feed it to an AI agent to generate PRDs automatically.

---

## What This Is

A reusable system for creating PRDs. It works two ways:

1. **Manual:** Answer the questionnaire, fill in the template
2. **AI-Powered:** Answer the questionnaire briefly, paste into an AI agent, get a complete PRD

---

## The PRD Builder Questionnaire

Answer these questions in 1–3 sentences each. The more specific, the better the PRD.

### Section A: The Idea

**A1. What is the app?**  
_Example: "A coaching practice management tool for solo coaches."_

**A2. What problem does it solve?**  
_Example: "Coaches juggle spreadsheets, calendars, and notes. This replaces all three."_

**A3. Who is the primary user?**  
_Example: "Independent life/career coaches with 5–50 active clients."_

**A4. What makes them choose this over alternatives?**  
_Example: "Cheaper than PracticeBetter, simpler than Salesforce, built for 1-person businesses."_

### Section B: Core Features

**B1. What are the 3–5 MUST-HAVE features for launch?**  
_Example:_
- _Client management (add, edit, archive)_
- _Session scheduling with calendar view_
- _Session notes per client_
- _Payment tracking_
- _Dashboard with alerts_

**B2. What features are NOT in the first version?**  
_Example: "Client portal, video calls, automated emails, mobile app."_

**B3. Are there different types of users?**  
_Example: "Just the coach for MVP. Clients might get a portal later."_

### Section C: Data & Logic

**C1. What are the main "things" in your app?**  
_Example: "Coaches, Clients, Sessions, Goals, Payments."_

**C2. How do they relate?**  
_Example: "A Coach has many Clients. A Client has many Sessions and Goals. A Session has Notes."_

**C3. Is there any special calculation or business logic?**  
_Example: "Payment status = sessions completed vs sessions paid for. Alert if no session in 14 days."_

### Section D: Screens & Flows

**D1. What screens does a user see after logging in?**  
_Example: "Dashboard, Clients list, Client detail, Session scheduler, Settings."_

**D2. What is the most important screen?**  
_Example: "The dashboard — it shows today's sessions, alerts, and quick stats."_

**D3. What is the main user flow?**  
_Example: "Login → Dashboard → Click client → Schedule session → Add notes → Mark complete."_

### Section E: Tech & Constraints

**E1. What tech stack do you prefer?**  
_Example: "Datastar + Go + SQLite."_

**E2. Any specific design direction?**  
_Example: "Clean and minimal like Linear. Dark mode support."_

**E3. Any hard constraints?**  
_Example: "Must work without JavaScript frameworks. Must be deployable on a $5 VPS."_

### Section F: Success Criteria

**F1. How do you know the MVP is done?**  
_Example: "I can add a client, schedule 3 sessions, write notes, record a payment, and see it all on the dashboard."_

**F2. What would make you pay for this?**  
_Example: "If it saves me 2 hours/week of admin work."_

---

## How to Use

### Method 1: Manual (You Write the PRD)

1. Copy `templates/PRD_TEMPLATE.md`
2. Fill in each section using your questionnaire answers
3. Done — you have a PRD

### Method 2: AI-Powered (AI Writes the PRD)

1. Answer the questionnaire above (takes 10–15 minutes)
2. Copy the AI prompt below
3. Paste into OpenCode / Claude / Cursor
4. The AI generates a complete PRD.md
5. Review and tweak

---

## AI Prompt: Generate PRD from Questionnaire

```
You are a senior product manager. Your job is to turn rough answers into a
professional, detailed Product Requirements Document (PRD).

Read the questionnaire answers below. Generate a complete PRD using the
structure from PRD_TEMPLATE.md. Be specific, actionable, and thorough.

RULES:
- Expand brief answers into detailed requirements
- Invent reasonable defaults where answers are vague
- Write user stories in "As a [user], I want [feature] so that [benefit]" format
- Define a complete data model with field types
- Include at least 5 screen wireframe descriptions
- Write 20+ test cases mapped to features
- Create a 4–5 phase MVP roadmap
- Output as a single markdown file

QUESTIONNAIRE ANSWERS:
[PASTE YOUR ANSWERS HERE]

OUTPUT:
A complete PRD.md following this structure:
1. Product Overview
2. Goals & Non-Goals
3. User Personas
4. User Stories (grouped by epic)
5. Data Model (entities, fields, types)
6. Page Flows
7. UI/UX Requirements
8. Business Logic
9. Security Requirements
10. Performance Requirements
11. Tech Stack
12. MVP Scope (phased)
13. Open Questions
```

---

## Method 3: Conversational (Talk to the AI)

Instead of answering all questions first, have a conversation:

```
You: "I want to build an app for my coaching side hustle."

AI: "Great! What kind of coaching? Who are your clients? What tools do you use now?"

You: "Life coaching. I use Google Calendar and spreadsheets. It's a mess."

AI: "What specifically is messy? Scheduling? Notes? Payments?"

You: "All of it. I forget follow-ups. I don't know who paid."

AI: [Generates PRD draft based on conversation]
```

This works best with Claude Opus or GPT-4 — models with strong conversational reasoning.

---

## Tips for Better PRDs

| Tip | Why It Helps |
|---|---|
| **Be specific about numbers** | "5–50 clients" is better than "some clients" |
| **Name your user** | "Alex, a solo coach" is better than "the user" |
| **List what you WON'T build** | Prevents scope creep and AI hallucination |
| **Describe the "happy path" flow** | Gives the AI a concrete sequence to implement |
| **Include a "done" definition** | Knows when to stop adding features |
| **Mention real tools you use now** | Helps the AI understand the problem space |

---

## Output

The final PRD should be a single file named `PRD.md` in your project root.

From there, the AI coding agent reads it and starts building.
