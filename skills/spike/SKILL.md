---
name: spike
description: Probe a technical uncertainty with a small, isolated, runnable spike before committing an approach to production. Use when the user says "build a spike", "let's test this", "try this in isolation", "prove whether this works", "create an experiment for this", or when browser behavior, an API/protocol design, concurrency, a database strategy, framework behavior, or a performance assumption is better answered by running code than by discussion. Discussion mode creates no files; execution mode creates .spikes/<YYYYMMDD-slug>/ containing spike.md and sandbox/.
---

# spike — Isolated Proof-of-Approach Laboratory

A spike is a small, self-contained, runnable proof of a specific technical
approach. Its job is to turn uncertainty into evidence, not to build
production software. A spike is not production-ready by default.

## Two modes

**Discussion mode (default).** Discuss the problem, inspect relevant code
(read-only), explain APIs, compare approaches, reason about architecture,
narrow the problem, identify risks and proof criteria.

> No `.spikes/` folder and no experimental files are created merely because a
> technical discussion is taking place. Conversational exploration must not
> modify the filesystem. A discussion may end with no spike — that is valid.

**Execution mode.** Begins only when a concrete objective exists. Triggered by
explicit user intent ("build a spike", "let's test this", "try this in
isolation", "prove whether this works", "create an experiment") or by the
agent recognizing a spike is the natural next step *after* the objective is
defined.

## Gate — before any file is written

Know all three:

1. **Problem** — what specific technical issue is being solved?
2. **Approach** — what solution or technique is being tested?
3. **Proof criteria** — what observable behavior demonstrates whether it works?

If any is missing, stay in discussion and ask. Do not scaffold first and
define the question later.

## Is a spike needed?

Useful when behavior is uncertain, docs are insufficient, approaches need
practical comparison, runtime/framework behavior needs verification,
performance needs measurement, or a cheap executable proof would reduce risk.

Not needed when the answer is already established, code inspection or docs
resolve it, the user is still brainstorming, or no concrete approach is chosen.

## Lifecycle

```
DEFINE PROBLEM -> DEFINE APPROACH -> PROOF CRITERIA -> SELECT PROFILE
  -> MINIMUM SELF-CONTAINED SOLUTION -> CREATE SPIKE -> RUN/VALIDATE
  -> OBSERVE -> DOCUMENT RESULT -> PROMOTE | KEEP | ABANDON | INCONCLUSIVE
```

## Target selection

Pick the environment that most directly reproduces the problem:

1. Existing project/runtime when required to reproduce the issue.
2. Standard capabilities of the chosen language/runtime.
3. Native platform APIs.
4. Minimal external dependencies.
5. Frameworks only when framework behavior is itself the question.

Use the smallest viable toolchain. Do not force JavaScript when another
runtime represents the problem better; do not add a framework when native
capabilities suffice. "Minimal" means no unnecessary complexity — compiled
stacks are fine when warranted.

## Profile routing (compact)

| Signal | Profile | Sandbox starting point |
|---|---|---|
| DOM, custom elements, CSS, Pointer/Web APIs, EventSource, IndexedDB | Native Web | `index.html`, `component.js`, `styles.css` |
| algorithms, parsers, streams, Node/Bun runtime | JS/TS | `spike.js`, `spike.test.js` |
| HTTP, concurrency, streaming, protocols, CLI | Go | `go.mod`, `main.go`, `main_test.go` |
| scripts, parsing, data, AI/ML | Python | `main.py`, `test_main.py` |
| Rails behavior (ActiveRecord, Turbo, ActionCable, jobs, locking) | Rails | disposable `Gemfile` + `app/` |
| systems, FFI, Wasm, perf | Rust | `Cargo.toml`, `src/main.rs` |
| low-level runtime, native interop | C/C++ | compilation permitted |
| project stack reproduction (React, Django, Postgres, Redis, Docker…) | Project-native | reuse project stack |
| untrusted/unsafe code | Sandboxed | Wasmtime/WASI/QuickJS/container limits |

See `reference/prd.md` §14 for the full matrix.

## Workspace

Create under `<project-root>/.spikes/`:

```
.spikes/
└── 20260923-go-sse-broadcast/
    ├── spike.md
    ├── sandbox/
    └── evidence/        # optional
```

- Naming: `YYYYMMDD-[descriptive-slug]`; add `-02`, `-03` on collision.
- Slug describes *what the spike proves*, not the whole feature.
- `spike.md` and `sandbox/` are required; `evidence/` is optional.
- `.spikes/` should be in the project's `.gitignore`.
- The project's production repository is **read-only by default**; only
  `.spikes/` is read/write. Do not modify production files to build a spike.

## spike.md

```markdown
# Spike: [Name]

## Problem
## Proposed Approach
## Objective
## Context
## Constraints
## Execution Profile
## Technologies / APIs
## Proof Criteria
## Files
## Run
## Observations
## Result          # PASS | FAIL | INCONCLUSIVE
## Production Implications
## Disposition     # PROMOTE | KEEP | ABANDON | INCONCLUSIVE
```

The spike directory must preserve the knowledge needed to reproduce the
experiment. A reader should not have to reconstruct the chat.

## sandbox/

The self-contained solution. Add files/manifests only when they contribute to
the proof. Typical run commands: `go test ./... && go run .`; `cargo test`;
`python3 -m http.server 8000 --directory sandbox` for native web.

## evidence/

Optional support for the conclusion: screenshots, logs, traces, benchmark
JSON, profiling data, test output. Never generated for ceremony alone.

## Execute and validate

Run with the platform's normal tooling. Testing should be proportional to what
must be proven — a tiny API experiment does not get enterprise test
infrastructure. When the platform cannot be exercised in this environment,
state that and provide exact commands for the user.

## Result and disposition

- **PASS** — approach demonstrated. **FAIL** — required behavior not met (still
  valuable: it eliminates an approach). **INCONCLUSIVE** — not enough evidence.
- **PROMOTE** — should inform production. **KEEP** — useful reference.
  **ABANDON** — rejected/no longer useful. **INCONCLUSIVE** — more work needed.
- Promotion is deliberate and separate: consider architecture, security, auth,
  observability, failure handling, config, maintainability, performance, tests,
  integration, deployment. A working spike is not automatically production code.

## Browser-based spikes

Discover capability before assuming it. Inspect available tools (MCP browser
tools, Chrome DevTools/CDP, Playwright/Puppeteer, desktop automation, IDE
preview). Selection order: dedicated MCP browser tool -> Chrome/Chromium DevTools
-> Playwright/Puppeteer -> desktop browser automation -> system default browser
-> manual instructions.

With browser control: start the local server, open the URL, exercise the
specific proof criteria, inspect console/network, resize to test responsive
behavior, capture screenshots. Keep validation focused on the objective; do not
grow an end-to-end suite just because automation exists.

Without browser control, still create the spike: serve it, give the local URL,
and explain the minimal interaction needed to verify behavior.

## Capability-aware execution

Discover first. Reuse second. Suggest third. Install only with permission.
Scan only for capabilities relevant to this spike (runtime, compiler, package
manager, browser tool, DB client, container) — never probe the whole machine.

## Approval gates

No extra approval loop is needed for safe, isolated `.spikes/` execution.
Additional confirmation *is* required before: modifying production files,
installing significant dependencies, using credentials, destructive operations,
creating cloud resources, modifying external services, or anything
security-sensitive. Do not install software or change the developer environment
without permission.

## Anti-patterns

- Creating files during brainstorming.
- Building before understanding (scaffold a system instead of isolating the
  uncertainty).
- Excessive scaffolding (framework + DB + Docker to test one API).
- Technology dogmatism (forcing one language for all spikes).
- Premature productionization.
- Treating a passing spike as production code.
- Endless experimentation: once the uncertainty is resolved, stop; new
  uncertainty becomes a new discussion or a separate spike.

## Behavior rules

1. Discussion before execution. 2. No files just because a conversation began.
3. Understand the problem before defining a spike. 4. Decide if a spike is
needed. 5. Define what it must prove. 6. Keep it narrowly focused.
7. Make it self-contained. 8. Prefer cheap executable evidence over prolonged
speculation. 9. Use the platform appropriate to the problem. 10. Prefer native
capabilities. 11. No frameworks without reason. 12. Do not avoid a framework
when its behavior is the problem. 13. Avoid unnecessary dependencies.
14. Production files read-only by default. 15. Record what was learned, not just
files generated. 16. Failed spikes are valid outcomes. 17. Stop when the
uncertainty is resolved. 18. Never quietly evolve a spike into production.

## Reference

Full specification: `reference/prd.md`.