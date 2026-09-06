# WIREFRAMES.md — CoachFlow

> Generated from PRD.md by DevKit Skill.
> This is an EXAMPLE of what the skill produces.

## Screen 1: Login

### Layout
- Full viewport height, centered content
- Max-width: 400px container

### Components
```
.container-narrow (centered)
  └── .stack-lg
      ├── .heading-2 "Welcome to CoachFlow"
      ├── .text-body "Sign in to manage your coaching practice"
      └── .card
          └── form
              ├── .form-group (email input)
              ├── .form-group (password input)
              ├── .alert.alert-danger (error state)
              └── .btn.btn-md.btn-primary (submit)
```

### Datastar Attributes
- `data-signals:email=""`, `data-signals:password=""`
- `data-on:click="@post('/api/login')"`

---

## Screen 2: Dashboard

### Layout
- Full app shell (sidebar + main content)
- Main content: `.container` with `.stack-lg`

### Components
```
main
  └── .stack-lg
      ├── header (.row.row-between)
      ├── stats grid (.grid.grid-4)
      ├── content row (.grid.grid-2)
      │   ├── today's sessions
      │   └── alerts
      └── recent clients
```

### Datastar Attributes
- `data-signals:todaySessions="[]"`
- `data-on:load="@get('/api/dashboard')"`

[... additional screens ...]

---

## Responsive Notes

### Mobile (< 768px)
- Sidebar becomes slide-out drawer
- Stats grid becomes 2-column then 1-column
- Tables become card lists
