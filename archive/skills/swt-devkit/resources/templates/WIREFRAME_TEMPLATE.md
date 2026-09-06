# WIREFRAMES.md — [APP_NAME]

> **For AI Coding Agents:** These are structural descriptions of each screen.
> Use these + your design system to build the actual UI.
> Do not generate images. Build the HTML directly.
>
> Generated from PRD.md Section 6 (Page Flows) and Section 7 (UI/UX Requirements).

---

## Wireframe Philosophy

Instead of drawing boxes, we describe the **information architecture** and **component composition** of each screen. The AI reads this, references the component library, and generates the actual HTML.

**Reference:** Your design system's component files for reusable patterns.

---

## Screen 1: [Screen Name from PRD]

### Layout
- [Describe the overall layout: full-width, sidebar, centered, etc.]
- [Max-width, padding, responsive behavior]

### Components
```
[Component hierarchy using your design system's class names]
.container / .container-narrow / .container-wide
  └── .stack / .stack-lg / .stack-xl
      ├── [Header section]
      ├── [Content section 1]
      ├── [Content section 2]
      └── [Footer/actions]
```

### Datastar Attributes
- `data-signals:` [list signals needed]
- `data-on:` [list actions]
- `data-show:` [list conditional rendering]

### Reference
- PRD Section: [which section this screen implements]
- User Stories: [which stories this screen serves]

---

## Screen 2: [Screen Name from PRD]

### Layout
- [Layout description]

### Components
```
[Component hierarchy]
```

### Datastar Attributes
- [List attributes]

### Reference
- PRD Section: [reference]
- User Stories: [reference]

---

## Screen 3: [Screen Name from PRD]

[Repeat structure...]

---

## Screen 4: [Modal/Form Screen from PRD]

### Layout
- Modal: `.modal-card` with max-width
- Or dedicated page if simpler

### Components
```
dialog (data-show="$showModal")
  └── .modal-card
      └── form
          ├── .heading-4 [title]
          ├── .stack [form fields]
          └── .card-footer [actions]
```

### Datastar Attributes
- `data-signals:` [form field signals]
- `data-on:click="@post('/api/...')"`
- `data-indicator:` [loading state]

---

## Responsive Notes

### Mobile (< 768px)
- [How layout adapts]
- [How tables become cards]
- [How modals become full-screen]

### Tablet (768px – 1024px)
- [Tablet adaptations]

### Desktop (> 1024px)
- [Full desktop layout]
