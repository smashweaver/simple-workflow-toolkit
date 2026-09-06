# Product Requirements Document (PRD)
# [APP_NAME]

> **For AI Coding Agents:** Read this file first. This is the single source of truth.
> All implementation decisions must align with this document.

---

## 1. Product Overview

**Name:** [APP_NAME]  
**Tagline:** [One sentence describing the value prop]  
**Type:** [Web app / Mobile app / API / etc.]  
**Target User:** [Who is this for? Be specific.]  
**Core Value:** [What problem does this solve in one sentence?]

---

## 2. Goals & Non-Goals

### Goals (Must Have for MVP)
- [ ] [Feature 1]
- [ ] [Feature 2]
- [ ] [Feature 3]
- [ ] [Feature 4]
- [ ] [Feature 5]

### Non-Goals (Post-MVP / Out of Scope)
- [ ] [Feature that sounds related but is NOT in MVP]
- [ ] [Feature that sounds related but is NOT in MVP]
- [ ] [Feature that sounds related but is NOT in MVP]

---

## 3. User Personas

### Primary: [Persona Name] ("[Nickname]")
- [Description: who they are, their situation]
- [Pain points: what frustrates them now]
- [Current tools: what they use today]
- [Tech comfort: low/medium/high]

### Secondary: [Persona Name] ("[Nickname]")
- [Description]
- [Pain points]
- [Current tools]
- [Tech comfort]

---

## 4. User Stories

### Epic 1: [Epic Name]
- As [persona], I want [action] so that [benefit].
- As [persona], I want [action] so that [benefit].
- As [persona], I want [action] so that [benefit].

### Epic 2: [Epic Name]
- As [persona], I want [action] so that [benefit].
- As [persona], I want [action] so that [benefit].
- As [persona], I want [action] so that [benefit].

### Epic 3: [Epic Name]
- As [persona], I want [action] so that [benefit].
- As [persona], I want [action] so that [benefit].

### Epic 4: [Epic Name]
- As [persona], I want [action] so that [benefit].
- As [persona], I want [action] so that [benefit].

### Epic 5: [Epic Name]
- As [persona], I want [action] so that [benefit].
- As [persona], I want [action] so that [benefit].

---

## 5. Data Model

### Entity: [Entity 1]
| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| [field] | [type] | [description] |
| [field] | [type] | [description] |
| [field] | [type] | [description] |
| created_at | timestamp | |
| updated_at | timestamp | |

### Entity: [Entity 2]
| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| [foreign_key] | UUID | FK to [Entity 1] |
| [field] | [type] | [description] |
| [field] | [type] | [description] |
| created_at | timestamp | |
| updated_at | timestamp | |

### Entity: [Entity 3]
| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| [field] | [type] | [description] |
| [field] | [type] | [description] |
| created_at | timestamp | |
| updated_at | timestamp | |

---

## 6. Page Flows

### Flow 1: [Flow Name]
1. [Step 1]
2. [Step 2]
3. [Step 3]
4. [Step 4]

### Flow 2: [Flow Name]
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Flow 3: [Flow Name]
1. [Step 1]
2. [Step 2]
3. [Step 3]
4. [Step 4]
5. [Step 5]

---

## 7. UI/UX Requirements

### Design Direction
- [Mood: clean/minimal / bold/energetic / warm/friendly / dark/cinematic]
- [Reference apps: "Like Linear/Notion/Stripe/Spotify"]
- [Density: tight/compact / normal / spacious]

### Key Screens
1. **[Screen 1]** — [What it does, key elements]
2. **[Screen 2]** — [What it does, key elements]
3. **[Screen 3]** — [What it does, key elements]
4. **[Screen 4]** — [What it does, key elements]
5. **[Screen 5]** — [What it does, key elements]

### Responsive
- [Mobile requirements]
- [Tablet requirements]
- [Desktop requirements]

---

## 8. Business Logic

### [Calculation 1]
```
[Describe the formula or rule]
```

### [Calculation 2]
```
[Describe the formula or rule]
```

### [Rule 1]
[Describe the business rule and when it applies]

---

## 9. Security Requirements

- [Authentication method]
- [Authorization rules]
- [Data protection]
- [Input validation]

---

## 10. Performance Requirements

- [Page load targets]
- [List pagination]
- [Search response time]
- [Concurrent users]

---

## 11. Tech Stack

| Layer | Technology |
|---|---|
| Frontend | [Framework] |
| CSS | [Approach] |
| Backend | [Language/Framework] |
| Database | [Database] |
| Auth | [Method] |
| Deployment | [Platform] |

---

## 12. MVP Scope

### Phase 1 (Week 1): [Phase Name]
- [ ] [Task 1]
- [ ] [Task 2]
- [ ] [Task 3]

### Phase 2 (Week 2): [Phase Name]
- [ ] [Task 1]
- [ ] [Task 2]
- [ ] [Task 3]

### Phase 3 (Week 3): [Phase Name]
- [ ] [Task 1]
- [ ] [Task 2]
- [ ] [Task 3]

### Phase 4 (Week 4): [Phase Name]
- [ ] [Task 1]
- [ ] [Task 2]
- [ ] [Task 3]

### Phase 5 (Week 5): [Phase Name]
- [ ] [Task 1]
- [ ] [Task 2]
- [ ] [Task 3]

---

## 13. Open Questions

- [ ] [Question about scope or priority]
- [ ] [Question about user behavior]
- [ ] [Question about technical approach]
