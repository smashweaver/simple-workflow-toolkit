# Test Plan — [APP_NAME]

> **For AI Coding Agents:** Implement tests for every scenario marked with [TEST].
> Each test maps directly to a user story or feature in PRD.md.
>
> Generated from PRD.md Section 4 (User Stories) and Section 9 (Security).

---

## Testing Philosophy

**Test Pyramid for this project:**
- **Unit tests:** Business logic ([list calculations from PRD Section 8])
- **Integration tests:** API endpoints (request → database → response)
- **E2E tests:** Critical user flows ([list main flows from PRD Section 6])

**All tests must be automated and runnable in CI.**

---

## 1. [Epic 1 Name] Tests

### TEST-001: [Feature] — Success Case
```
Given: [precondition]
When: [action]
Then: [expected outcome]
And: [additional checks]
```

### TEST-002: [Feature] — Validation Error
```
Given: [precondition]
When: [invalid action]
Then: [error response]
And: [state unchanged]
```

### TEST-003: [Feature] — Authorization
```
Given: [unauthorized user]
When: [action]
Then: [403/404 response]
```

[Continue for each user story in Epic 1...]

---

## 2. [Epic 2 Name] Tests

[Same structure...]

---

## 3. [Epic 3 Name] Tests

[Same structure...]

---

## 4. Business Logic Tests

### TEST-[XXX]: [Calculation Name]
```
Given: [input values]
When: [calculation runs]
Then: [expected output]
```

[Reference PRD Section 8 for each calculation...]

---

## 5. Security Tests

### TEST-[XXX]: [Attack Vector]
```
Given: [malicious input]
When: [submitted to endpoint]
Then: [safely handled]
And: [no data leaked]
```

[Reference PRD Section 9...]

---

## 6. Performance Tests

### TEST-[XXX]: [Performance Scenario]
```
Given: [load condition]
When: [action]
Then: [response time < threshold]
```

[Reference PRD Section 10...]

---

## Test Implementation Priority

### P0 (MVP Blockers) — Implement First
- [List critical tests]

### P1 (Important) — Implement Second
- [List important tests]

### P2 (Nice to Have) — Post-MVP
- [List nice-to-have tests]
