# Product Requirements Document (PRD)
# CoachFlow

> **For AI Coding Agents:** Read this file first. This is the single source of truth.
> All implementation decisions must align with this document.

---

## 1. Product Overview

**Name:** CoachFlow  
**Tagline:** Run your coaching practice without the admin headache.  
**Type:** Web application (SaaS for solo coaches)  
**Target User:** Independent life/career/health coaches with 5–50 active clients  
**Core Value:** Replace spreadsheets, calendar juggling, and email threads with one simple dashboard.

---

## 2. Goals & Non-Goals

### Goals (Must Have for MVP)
- [ ] Client management (CRUD + notes + status)
- [ ] Session scheduling with calendar integration
- [ ] Session notes & goal tracking per client
- [ ] Simple payment tracking (who paid, who owes)
- [ ] Dashboard with upcoming sessions & alerts
- [ ] Basic authentication (coach login only)

### Non-Goals (Post-MVP)
- [ ] Client portal (clients logging in)
- [ ] Video calling integration
- [ ] Automated email sequences
- [ ] Multi-coach support
- [ ] Mobile native app
- [ ] AI coaching suggestions

---

## 3. User Personas

### Primary: The Solo Coach ("Alex")
- 1-person coaching business
- 10–30 active clients
- Uses Google Calendar + spreadsheets + Notes app
- Pain: Forgetting follow-ups, losing track of client goals, chasing payments
- Tech comfort: Medium (uses Notion, Calendly, Stripe)

### Secondary: The Growing Coach ("Jordan")
- Just hired a VA or considering it
- 30–50 clients, group coaching
- Needs reporting and organization
- Pain: Can't scale without systems

---

## 4. User Stories

### Epic 1: Client Management
- As Alex, I want to add a new client with name, email, phone, and coaching focus so I have all their info in one place.
- As Alex, I want to view a list of all my clients with their current status so I can see who needs attention.
- As Alex, I want to edit client details so I can keep information current.
- As Alex, I want to archive a client (not delete) so I retain history if they pause coaching.
- As Alex, I want to add private notes to a client record so I remember context between sessions.
- As Alex, I want to tag clients by coaching type (career, life, health, executive) so I can filter my list.

### Epic 2: Session Scheduling
- As Alex, I want to schedule a coaching session with a client so it's on my calendar.
- As Alex, I want to see all upcoming sessions in a list view so I know what's coming.
- As Alex, I want to mark a session as completed, cancelled, or no-show so my records are accurate.
- As Alex, I want to reschedule a session so I can handle changes.
- As Alex, I want to set my available hours so I don't get double-booked.
- As Alex, I want to see sessions by client so I can view their history.

### Epic 3: Session Notes & Goals
- As Alex, I want to write notes during or after a session so I capture what we discussed.
- As Alex, I want to set goals with a client and track progress so we stay aligned.
- As Alex, I want to view all notes for a client in chronological order so I can prepare for our next session.
- As Alex, I want to mark a goal as achieved so I can celebrate wins.

### Epic 4: Payments
- As Alex, I want to record when a client pays me so I know who is current.
- As Alex, I want to see which clients have upcoming or overdue payments so I can follow up.
- As Alex, I want to set a client's package type (e.g., 6 sessions for $600) so payment tracking is automatic.
- As Alex, I want to see my monthly revenue at a glance so I understand my business.

### Epic 5: Dashboard & Alerts
- As Alex, I want to see today's sessions when I log in so I know my day.
- As Alex, I want to see clients I haven't spoken to in 2+ weeks so I can re-engage.
- As Alex, I want to see overdue payments so I can send reminders.
- As Alex, I want to see upcoming goals deadlines so I can prepare.

---

## 5. Data Model

### Entity: Coach (User)
| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| email | string | Unique, used for login |
| password_hash | string | bcrypt |
| name | string | Display name |
| timezone | string | IANA timezone (e.g., "America/New_York") |
| created_at | timestamp | |
| updated_at | timestamp | |

### Entity: Client
| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| coach_id | UUID | FK to Coach |
| name | string | |
| email | string | |
| phone | string | Optional |
| focus_area | enum | career, life, health, executive, other |
| status | enum | active, paused, completed, archived |
| package_type | string | e.g., "6-session", "monthly", "pay-as-you-go" |
| package_total | decimal | Total package value |
| package_sessions | integer | Sessions included in package |
| notes | text | Private coach notes |
| created_at | timestamp | |
| updated_at | timestamp | |

### Entity: Session
| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| client_id | UUID | FK to Client |
| coach_id | UUID | FK to Coach |
| scheduled_at | timestamp | Start time |
| duration_minutes | integer | Default 60 |
| status | enum | scheduled, completed, cancelled, no_show |
| notes | text | Session notes |
| created_at | timestamp | |
| updated_at | timestamp | |

### Entity: Goal
| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| client_id | UUID | FK to Client |
| title | string | |
| description | text | Optional |
| status | enum | active, achieved, abandoned |
| target_date | date | Optional |
| created_at | timestamp | |
| updated_at | timestamp | |

### Entity: Payment
| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| client_id | UUID | FK to Client |
| amount | decimal | |
| payment_date | date | |
| method | enum | cash, bank_transfer, stripe, other |
| notes | text | Optional |
| created_at | timestamp | |

---

## 6. Page Flows

### Flow 1: First Login → Dashboard
1. Coach logs in (email + password)
2. Redirected to Dashboard
3. Dashboard shows: today's sessions, alerts (overdue payments, stale clients), quick stats

### Flow 2: Add New Client
1. Coach clicks "New Client" button
2. Fills form: name, email, phone, focus area, package type
3. Submits → Client created → Redirected to Client Detail page
4. Client Detail shows: info card, session history, goals, notes, payment status

### Flow 3: Schedule Session
1. From Client Detail or Dashboard, click "Schedule Session"
2. Pick date/time from calendar picker
3. Select client (if not already on their page)
4. Set duration (default 60 min)
5. Submit → Session created → Appears on Dashboard and Client Detail

### Flow 4: Post-Session Notes
1. Coach views today's session
2. Clicks "Add Notes"
3. Writes session notes
4. Optionally updates goal progress
5. Marks session as "Completed"

### Flow 5: Payment Tracking
1. Coach views Client Detail
2. Clicks "Record Payment"
3. Enters amount, date, method
4. System updates client's payment status
5. Dashboard alerts update

---

## 7. UI/UX Requirements

### Design Direction
- Clean, minimal, professional aesthetic (think Linear/Notion, not bubbly)
- Sidebar navigation on desktop, top nav on mobile
- Cards for content grouping
- Tables for lists (clients, sessions, payments)
- Forms in modals or dedicated pages

### Key Screens
1. **Login** — Simple centered form, minimal
2. **Dashboard** — Stats cards + today's sessions + alerts sidebar
3. **Clients List** — Table with filters (status, focus area) + search
4. **Client Detail** — Tabbed layout: Overview | Sessions | Goals | Notes | Payments
5. **Session Scheduler** — Calendar picker + client selector
6. **Settings** — Profile, availability hours, notification prefs

### Responsive
- Mobile-first for core flows
- Sidebar collapses to hamburger on mobile
- Tables scroll horizontally on small screens
- Modals become full-screen on mobile

---

## 8. Business Logic

### Payment Status Calculation
```
sessions_completed = count of completed sessions for client
sessions_paid_for = client's recorded payments / (package_total / package_sessions)
payment_status = 
  if sessions_paid_for >= sessions_completed: "current"
  if sessions_paid_for < sessions_completed: "overdue by {diff} sessions"
```

### Stale Client Alert
```
last_session = max(session.scheduled_at where status = 'completed')
if today - last_session > 14 days: alert "No session in {days} days"
```

### Revenue Calculation
```
monthly_revenue = sum(payment.amount where payment_date in current month)
```

---

## 9. Security Requirements

- Passwords hashed with bcrypt
- Sessions via secure HTTP-only cookies
- All routes require authentication except login/register
- Coaches can only see their own clients/data
- Input sanitization on all text fields
- Rate limiting on login attempts

---

## 10. Performance Requirements

- Page load < 500ms for dashboard
- Lists paginated at 25 items
- Search debounced at 300ms
- SSE updates for real-time session status changes

---

## 11. Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Datastar (hypermedia, server-rendered HTML) |
| CSS | Custom properties (tokens.css + components.css from Datastar Skill) |
| Backend | [Go / Python / Node — choose one] |
| Database | SQLite (MVP) → PostgreSQL (scale) |
| Auth | Session-based (HTTP-only cookies) |
| Deployment | [Your platform] |

---

## 12. MVP Scope

### Phase 1 (Week 1): Foundation
- [ ] Project setup + database schema
- [ ] Auth (login/register)
- [ ] Base layout + navigation
- [ ] Dashboard shell

### Phase 2 (Week 2): Clients
- [ ] Client CRUD
- [ ] Client list + search/filter
- [ ] Client detail page

### Phase 3 (Week 3): Sessions
- [ ] Session scheduling
- [ ] Session list + status management
- [ ] Calendar view (simple)

### Phase 4 (Week 4): Notes, Goals, Payments
- [ ] Session notes
- [ ] Goal tracking
- [ ] Payment recording
- [ ] Dashboard alerts

### Phase 5 (Week 5): Polish
- [ ] Responsive mobile
- [ ] Settings page
- [ ] Data export (CSV)
- [ ] Bug fixes + refinement

---

## 13. Open Questions

- [ ] Should clients receive email confirmations for scheduled sessions? (Post-MVP)
- [ ] Should there be a "session template" feature for recurring structures? (Post-MVP)
- [ ] Should payment integration with Stripe be direct or manual entry only? (MVP = manual)
