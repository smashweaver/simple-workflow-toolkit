# Test Plan — CoachFlow

> Generated from PRD.md by DevKit Skill.
> This is an EXAMPLE of what the skill produces.

## 1. Authentication Tests

### TEST-001: Coach Registration
```
Given: A new coach visits registration
When: Submit valid email, name, password, timezone
Then: New coach record created
And: Redirected to dashboard
```

### TEST-002: Login Success
```
Given: Coach exists with correct credentials
When: Login submitted
Then: Session cookie set
And: Redirected to /dashboard
```

[... 80+ tests ...]

## Test Implementation Priority

### P0 (MVP Blockers)
- TEST-001 through TEST-008 (Auth)
- TEST-101 through TEST-112 (Client CRUD)

### P1 (Important)
- TEST-201 through TEST-209 (Sessions)
- TEST-301 through TEST-304 (Goals)
