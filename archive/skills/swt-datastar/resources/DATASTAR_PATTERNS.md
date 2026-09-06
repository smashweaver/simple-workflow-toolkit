# Datastar Patterns — Agent Reference

> Read this file BEFORE writing any Datastar markup.
> This is a curated, project-specific reference — not the full API.
> For the complete API, see the official docs: https://data-star.dev

## Core Philosophy

Datastar is a **hypermedia framework**. The server renders HTML. The browser patches the DOM via Server-Sent Events (SSE). There is no client-side state management library. All interactivity is declarative via `data-*` attributes.

**Golden Rule:** If you're tempted to write custom JavaScript, use a Datastar attribute instead.

---

## Signals

Signals are reactive variables. They live in the DOM and update automatically.

### Initialization

```html
<!-- Initialize a signal with a default value -->
<div data-signals:count="0"></div>

<!-- Initialize only if missing (safe for fragments) -->
<div data-signals:count__ifmissing="0"></div>

<!-- Local-only signal (not sent to server) -->
<div data-signals:_local="value"></div>

<!-- Multiple signals -->
<div data-signals="{count: 0, name: '', loading: false}"></div>
```

### Accessing Signals

Use `$` prefix in expressions:

```html
<span data-text="$count"></span>
<div data-show="$count > 0">Has items</div>
<button data-on:click="$count++">Increment</button>
```

### Computed Signals

```html
<div data-computed:double="$count * 2"></div>
<span data-text="$double"></span>
```

---

## Backend Requests (Actions)

Datastar sends requests to the server and patches the DOM with the response.

### GET — Fetch a fragment

```html
<button data-on:click="@get('/api/fragment')">Load</button>
```

### POST — Submit data

```html
<button data-on:click="@post('/api/save')">Save</button>
```

### PUT / PATCH / DELETE

```html
<button data-on:click="@put('/api/update')">Update</button>
<button data-on:click="@patch('/api/patch')">Patch</button>
<button data-on:click="@delete('/api/delete')">Delete</button>
```

### With Signals as JSON Body

```html
<button data-on:click="@post('/api/save', {contentType: 'json'})">Save JSON</button>
```

The server receives all signals as JSON. Use `data-signals:_local` for values you don't want sent.

---

## Event Modifiers

Append modifiers to `data-on:` attributes with double underscore.

| Modifier | Effect | Example |
|---|---|---|
| `__once` | Fire only once | `data-on:click__once="@post('/api/once')"` |
| `__debounce.500ms` | Wait 500ms after last trigger | `data-on:input__debounce.300ms="@post('/api/search')"` |
| `__throttle.250ms` | Fire at most every 250ms | `data-on:scroll__throttle.100ms="..."` |
| `__duration.2s` | Run for 2 seconds max | `data-on:click__duration.2s="..."` |
| `__viewtransition` | Use View Transitions API | `data-on:click__viewtransition="@get('/page')"` |
| `__case.kebab` | Convert signal names to kebab-case in request | `data-signals:myValue__case.kebab` |
| `__ifmissing` | Set default only if signal doesn't exist | `data-signals:count__ifmissing="0"` |

---

## Reactivity Attributes

### Show / Hide

```html
<div data-show="$isVisible">Shown when true</div>
<div data-show="!$isLoading">Hidden when loading</div>
```

### Text Content

```html
<span data-text="$count"></span>
<span data-text="'Items: ' + $count"></span>
```

### Class Toggling

```html
<div data-class:active="$isActive">Toggles .active</div>
<div data-class:hidden="!$isVisible">Toggles .hidden</div>
```

### Attribute Binding

```html
<input data-attr:disabled="$isLoading" />
<input data-attr:readonly="$isReadOnly" />
<img data-attr:src="$imageUrl" />
```

### Two-Way Binding

```html
<input data-bind="searchQuery" />
<textarea data-bind="description"></textarea>
<select data-bind="category">
  <option value="a">A</option>
  <option value="b">B</option>
</select>
```

### Scroll Into View

```html
<div data-scroll-into-view="$shouldScroll"></div>
```

### Intersection Observer

```html
<div data-intersects="$isVisible = true">Triggers when scrolled into view</div>
```

---

## Loading States (data-indicator)

**PREFERRED over manual signal toggling.**

When a backend request is in flight, Datastar automatically creates a signal named after the indicator. Use it to show spinners, disable buttons, etc.

```html
<!-- The indicator signal is auto-created as $loading -->
<button 
  data-on:click="@post('/api/save')"
  data-indicator:loading>
  <span data-show="!$loading">Save</span>
  <span data-show="$loading">Saving...</span>
</button>

<!-- Disable input while loading -->
<input data-attr:disabled="$loading" data-bind="name" />

<!-- Show global spinner -->
<div class="spinner" data-show="$loading"></div>
```

---

## Effects

Run side effects when signals change:

```html
<div data-effect="console.log('count changed:', $count)"></div>
```

---

## Refs

Access DOM elements directly:

```html
<input data-ref:searchInput />
<button data-on:click="$searchInput.focus()">Focus</button>
```

---

## Fragments & Polling

### Auto-refresh a fragment

```html
<div data-on:load__delay.5s="@get('/api/status')"></div>
```

### Polling

```html
<div data-on:load__delay.5s__throttle.5s="@get('/api/updates')"></div>
```

---

## Accessibility Patterns

### Modal (Native `<dialog>`)

```html
<button data-on:click="$showModal = true">Open</button>

<dialog id="modal" data-show="$showModal" data-on:keydown.esc="$showModal = false">
  <div class="card modal-card">
    <h3>Title</h3>
    <p>Content</p>
    <button data-on:click="$showModal = false">Close</button>
  </div>
</dialog>
```

**Note:** `data-show` on `<dialog>` handles `showModal()` and `close()` automatically.

### Dropdown (Native `<details>`)

```html
<details>
  <summary>Menu</summary>
  <div class="card">
    <a href="/profile">Profile</a>
    <a href="/settings">Settings</a>
  </div>
</details>
```

### Tabs (Radio buttons + CSS)

```html
<div class="tabs">
  <label>
    <input type="radio" name="tab" data-bind="activeTab" value="general" checked />
    <span>General</span>
  </label>
  <label>
    <input type="radio" name="tab" data-bind="activeTab" value="security" />
    <span>Security</span>
  </label>
</div>

<div data-show="$activeTab === 'general'">General content</div>
<div data-show="$activeTab === 'security'">Security content</div>
```

### Toast / Alert (Live region)

```html
<div role="status" aria-live="polite" data-show="$toastMessage">
  <div class="alert alert-success" data-text="$toastMessage"></div>
</div>
```

---

## Anti-Patterns (NEVER DO)

- ❌ **Don't use `$` or `$$` magic functions** — removed in Datastar V1. Use `data-ref` instead.
- ❌ **Don't manually toggle loading states** — use `data-indicator`.
- ❌ **Don't use double underscores in signal names** — reserved for modifiers. Use camelCase or kebab-case.
- ❌ **Don't write custom JavaScript** — all interactivity should be declarative.
- ❌ **Don't use `eval()` or `Function()`** — expressions are sandboxed.
- ❌ **Don't rely on client-side state for security** — always validate on the server.

---

## Expression Syntax Quick Ref

Datastar expressions are JavaScript-like but sandboxed:

```
$count + 1
$count > 0 && $count < 10
$name || 'Anonymous'
$items.length
$isLoading ? 'Loading...' : 'Done'
$searchQuery.toLowerCase()
```

**Available globals in expressions:**
- `$signalName` — any signal
- `el` — the current element
- `event` — the triggering event
- `$$refs` — all refs
- `$$signals` — all signals

---

## Backend Response Format

The server should return HTML fragments. Datastar patches them into the DOM:

```html
<!-- Server responds with: -->
<div id="target">
  <p>Updated content</p>
</div>

<!-- Datastar merges this into the element with id="target" -->
```

Use `data-signals` in the response to update signals:

```html
<div data-signals="{count: 42}"></div>
```

---

## Resources

- Official Docs: https://data-star.dev
- GitHub: https://github.com/starfederation/datastar
- Full Reference (for LLM ingestion): https://github.com/banditburai/starHTML/blob/main/DATASTAR_REFERENCE.md
