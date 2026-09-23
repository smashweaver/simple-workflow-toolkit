# PRODUCT REQUIREMENT DOCUMENT (PRD)

## AI AGENT SKILL: SPIKE LAB

Version: 1.1
Status: Draft Reference Specification
Target: AI Developer Agents / Coding Agents

---

# 1. EXECUTIVE SUMMARY

Spike Lab is a specialized skill for AI developer agents that helps software engineers explore technical problems, discuss possible solutions, and—when useful—create small, isolated, self-contained executable spikes.

A spike is:

> A small, self-contained, executable proof of a solution or approach to a specific technical problem or uncertainty.

A spike contains enough code, configuration, documentation, and supporting files to understand, run, and evaluate an approach independently.

A spike is not necessarily production-ready.

Its purpose is to prove whether an approach works before committing that approach to the production codebase.

Spike Lab therefore operates in two distinct modes:

```
DISCUSSION MODE
    ↓
no spike files are created
```

and:

```
SPIKE EXECUTION MODE
    ↓
an isolated spike workspace is created
```

Technical discussion does not automatically create a spike.

The agent first helps the developer understand the problem, explore possible approaches, and determine whether an executable spike is useful.

Only when a concrete spike objective has been established does Spike Lab transition into execution.

Spike Lab is language- and platform-agnostic.

It has a strong preference for the smallest practical runtime, language, framework, or toolchain capable of proving the proposed solution.

For browser-focused experiments, this often means native HTML, CSS, JavaScript, and Web APIs.

For backend, systems, networking, concurrency, database, framework, protocol, or infrastructure questions, Spike Lab may instead use Go, Python, Ruby, Rails, Rust, C/C++, Node.js, Bun, or another appropriate environment.

The objective is not to force experiments into a particular technology.

The objective is to minimize the distance between:

```
technical problem
    ↓
proposed approach
    ↓
self-contained spike
    ↓
observable evidence
    ↓
technical conclusion
```

---

# 2. PRODUCT OBJECTIVES

Spike Lab must:

1. Support technical discussion without automatically generating files.

2. Help isolate a specific technical problem or uncertainty.

3. Explore possible approaches conversationally.

4. Determine whether a spike is actually needed.

5. Convert a chosen approach into a clearly defined spike objective.

6. Define what the spike must prove.

7. Select the smallest suitable execution environment.

8. Generate a self-contained executable spike.

9. Keep experimental code isolated from production code.

10. Avoid unnecessary scaffolding, dependencies, infrastructure, and build tooling.

11. Execute or validate the spike when the environment permits.

12. Record observations and conclusions.

13. Preserve useful spikes as technical reference material.

14. Allow successful spikes to later inform production implementation.

---

# 3. CORE DEFINITION

## 3.1 What Is a Spike?

A spike is:

> A small, self-contained, executable proof of a solution or approach to a specific technical problem or uncertainty.

A spike should contain everything necessary to:

* understand the problem being investigated
* understand the proposed approach
* run the solution in isolation
* observe its behavior
* evaluate whether the approach works

A spike may demonstrate:

* a browser behavior
* a UI interaction
* an API design
* a protocol
* a concurrency pattern
* a database strategy
* a framework capability
* an algorithm
* an architectural idea
* an integration mechanism
* a performance assumption
* a runtime behavior

A spike does not need to contain everything required for production.

It normally excludes concerns that do not affect the technical question being investigated.

Examples of concerns that may intentionally be omitted:

* production authentication
* deployment infrastructure
* full observability
* extensive error handling
* complete UX
* production security hardening
* scalability infrastructure
* broad application architecture

unless one of those concerns is itself the subject of the spike.

---

# 4. CORE PRODUCT PRINCIPLE

Spike Lab optimizes for proving an approach, not completing a production feature.

Every spike should be the smallest self-contained solution capable of resolving a clearly stated technical question.

Examples:

```
Can CSS Anchor Positioning replace our JavaScript
tooltip positioning logic?

Can a Custom Element encapsulate this widget without
Shadow DOM?

Can Go's standard HTTP library provide our required
Server-Sent Events behavior?

Does this PostgreSQL locking strategy prevent the
race condition?

Does Rails Turbo preserve ordering under this
interaction pattern?

Can SQLite support the expected concurrent
write workload?

Does this serialization strategy outperform the
current implementation for the expected data shape?
```

The agent should resist turning a spike into a complete application unless application-level structure is necessary to prove the approach.

---

# 5. OPERATING MODES

Spike Lab has two primary modes.

---

# 5.1 MODE A: DISCUSSION MODE

Discussion Mode is the default state.

The agent may:

* discuss the technical problem
* inspect relevant source code
* explain APIs
* compare approaches
* reason about architecture
* suggest possible experiments
* identify risks
* identify assumptions
* narrow the problem
* define possible success criteria

During Discussion Mode:

> No spike folder or experimental files should be created merely because a technical discussion is taking place.

Conversational exploration alone must not modify the filesystem.

The discussion may continue indefinitely without ever producing a spike.

A spike should only be created when executing an isolated solution would materially help resolve the question.

---

# 5.2 MODE B: SPIKE EXECUTION MODE

Spike Execution Mode begins when a concrete spike objective exists.

Examples of explicit user intent include:

```
Build a spike for this.

Let's test this approach.

Try this in isolation.

Prove whether this works.

Create an experiment for this.
```

The agent may also recognize that a spike is the natural next step after discussion, but it must first have a sufficiently defined objective.

At minimum, the agent should know:

* what problem is being investigated
* what approach is being tested
* what the spike should prove

Only then should it create a spike workspace.

---

# 6. TRANSITION FROM DISCUSSION TO EXECUTION

The transition should conceptually follow:

```
DISCUSS
    ↓
UNDERSTAND PROBLEM
    ↓
EXPLORE APPROACHES
    ↓
IS A SPIKE USEFUL?
    ↓
  NO ─────→ CONTINUE DISCUSSION
    ↓ YES
DEFINE SPIKE OBJECTIVE
    ↓
DEFINE WHAT MUST BE PROVEN
    ↓
SELECT EXECUTION PROFILE
    ↓
CREATE SPIKE WORKSPACE
    ↓
EXECUTE
    ↓
OBSERVE
    ↓
DOCUMENT RESULT
```

The creation of `.spikes/` occurs only after the workflow reaches:

```
CREATE SPIKE WORKSPACE
```

---

# 7. SPIKE LIFECYCLE

Once Spike Execution Mode begins, the lifecycle is:

```
DEFINE PROBLEM
    ↓
DEFINE APPROACH
    ↓
DEFINE PROOF CRITERIA
    ↓
SELECT EXECUTION PROFILE
    ↓
DEFINE MINIMUM SELF-CONTAINED SOLUTION
    ↓
CREATE SPIKE
    ↓
VALIDATE / RUN
    ↓
OBSERVE
    ↓
DOCUMENT RESULT
    ↓
PROMOTE | KEEP | ABANDON | INCONCLUSIVE
```

---

# 8. GUIDED TECHNICAL DISCUSSION

The agent analyzes the developer's technical objective and identifies the actual problem being investigated.

Discussion may include:

* architecture
* implementation options
* browser APIs
* language features
* runtime behavior
* framework behavior
* concurrency
* protocols
* databases
* performance
* integration constraints
* existing production code
* legacy implementations
* alternative approaches

The agent should avoid unnecessary interrogation.

If sufficient context already exists, it should continue naturally.

The objective is not necessarily to immediately formulate a spike.

The objective is first to help the developer understand the technical problem.

---

# 9. DETERMINING WHETHER A SPIKE IS NEEDED

Not every technical discussion requires a spike.

A spike is useful when:

* behavior is uncertain
* documentation alone is insufficient
* competing approaches need practical comparison
* runtime behavior needs verification
* performance needs measurement
* framework behavior needs reproduction
* an architectural assumption can be cheaply tested
* a small executable proof would reduce implementation risk

A spike may not be necessary when:

* the answer is already well established
* the issue can be resolved through code inspection
* documentation clearly answers the question
* the user is still brainstorming broadly
* no concrete approach has been selected

---

# 10. DEFINING THE SPIKE

Before creating files, the agent should establish three things.

## Problem

What specific technical issue is being solved?

## Approach

What proposed solution or technique is being tested?

## Proof Criteria

What observable behavior would demonstrate whether the approach works?

Example:

Problem:

```
We need one-way realtime updates from the server.
```

Approach:

```
Use Server-Sent Events implemented with Go's standard library.
```

Proof criteria:

* several browser clients can connect
* all connected clients receive events
* disconnected clients are cleaned up
* no third-party Go package is required

The resulting spike should be just large enough to prove these points.

---

# 11. TARGET SELECTION AND PROFILE ROUTING

The agent selects the environment that most directly reproduces the technical problem.

Selection preference:

1. Existing project/runtime when required to reproduce the issue.

2. Standard capabilities of the selected language/runtime.

3. Native platform APIs.

4. Minimal external dependencies.

5. Frameworks when the framework itself materially affects the question.

The agent must not force JavaScript when another language or runtime better represents the problem.

Likewise, the agent should not introduce a framework when native capabilities can answer the question more directly.

---

# 12. EXECUTION BLUEPRINT

Before file generation, the agent should internally establish a lightweight execution blueprint.

The blueprint may contain:

* problem
* proposed approach
* spike objective
* proof criteria
* selected execution profile
* expected files
* runtime commands
* validation method
* expected observations

The blueprint does not have to be printed to the user.

The agent may show it when useful.

The agent should avoid unnecessary approval loops for safe, isolated spike execution.

Additional confirmation may be appropriate when:

* production files would be modified
* significant dependencies must be installed
* credentials are required
* destructive operations are involved
* cloud resources would be created
* external services would be modified
* the action is security-sensitive

---

# 13. SELF-CONTAINED SPIKE REQUIREMENT

A generated spike should be understandable and runnable independently.

A spike should normally include:

* its objective
* required source files
* required configuration
* execution instructions
* dependencies, if any
* expected behavior
* observations
* conclusion

A developer should not have to reverse-engineer the AI conversation in order to understand the spike later.

The spike directory itself should preserve the knowledge required to reproduce the experiment.

---

# 14. EXECUTION PROFILE MATRIX

Execution profiles are routing strategies rather than restrictions.

---

## 14.1 Native Web UI

Use for:

* DOM behavior
* Custom Elements
* Web Components
* Canvas
* Web Animations
* browser events
* Pointer Events
* Drag and Drop
* Fetch
* EventSource
* WebSockets
* IndexedDB
* native forms
* CSS behavior
* browser layout

Preferred stack:

* HTML
* CSS
* modern JavaScript
* native Web APIs

Defaults:

* no bundler
* no compilation
* no npm installation
* direct ES modules
* browser-executable files

Typical files:

```
sandbox/
├── index.html
├── component.js
└── styles.css
```

---

## 14.2 JavaScript / TypeScript

Use for:

* algorithms
* parsers
* transformations
* protocols
* benchmarks
* data structures
* asynchronous behavior
* streams
* runtime behavior

Preferred runtime:

* Node.js
* Bun

TypeScript may be used when TypeScript behavior is relevant or when the local project already supports direct execution.

---

## 14.3 Go

Use for:

* HTTP services
* APIs
* networking
* goroutines
* channels
* concurrency
* command-line tools
* streaming
* protocols
* database access
* backend architecture
* performance testing

Typical files:

```
sandbox/
├── go.mod
├── main.go
└── main_test.go
```

Typical execution:

```
go test ./...
go run .
```

---

## 14.4 Python

Use for:

* scripts
* data transformations
* backend experiments
* automation
* parsing
* AI/ML experimentation
* protocol exploration
* interoperability testing

Prefer the standard library when practical.

---

## 14.5 Ruby

Use for:

* Ruby language behavior
* service objects
* DSL experiments
* parsing
* concurrency
* business logic
* integration logic

Prefer standalone Ruby when Rails is unnecessary.

---

## 14.6 Rails

Use when Rails itself affects the problem.

Examples:

* ActiveRecord
* Turbo
* ActionCable
* ActiveJob
* callbacks
* transactions
* locking
* routing
* middleware
* caching
* request lifecycle

A small disposable Rails application is legitimate when Rails must exist for the behavior to be reproduced.

---

## 14.7 Rust

Use for:

* systems behavior
* memory-sensitive code
* concurrency
* FFI
* WebAssembly
* performance
* native services
* low-level protocols

Typical execution:

```
cargo test
cargo run
```

---

## 14.8 C / C++

Use when lower-level runtime behavior, native interoperability, system APIs, or performance requires them.

Compilation is permitted.

Spike Lab minimizes unnecessary tooling; it does not prohibit compilation.

---

## 14.9 Project-Native Runtime

Spike Lab may use the project's existing stack when reproducing the issue requires it.

Examples:

* React
* Vue
* Svelte
* Electron
* Django
* Phoenix
* Spring
* .NET
* Swift
* Laravel
* Cloudflare Workers
* PostgreSQL
* Redis
* SQLite
* Docker

Framework use is valid when framework behavior is part of what must be proven.

---

## 14.10 Sandboxed / Untrusted Execution

This profile is specifically for potentially unsafe or untrusted code.

Possible isolation technologies include:

* Wasmtime
* WASI
* QuickJS
* containers
* OS-level sandboxing

Possible restrictions include:

* filesystem isolation
* no network access by default
* execution timeout
* memory limits
* process isolation

Limits should be configurable for the experiment.

---

# 15. MINIMAL ENVIRONMENT PRINCIPLE

Spike Lab follows:

> Use the smallest viable toolchain and dependency set required to prove the proposed solution.

Examples:

Native Web:

```
HTML + CSS + JavaScript
```

Go:

```
standard Go toolchain
```

Python:

```
Python interpreter
```

Rust:

```
Cargo + compiler
```

Rails:

```
Rails when Rails behavior is being tested
```

Spike Lab should avoid unnecessary:

* package installation
* bundlers
* containers
* databases
* frameworks
* infrastructure
* cloud resources
* application scaffolding

The word "minimal" refers to unnecessary complexity, not to a requirement that every spike use interpreted or zero-build technology.

---

# 16. WORKSPACE ISOLATION

Spike workspaces are created under:

```
<project-root>/.spikes/
```

Important:

> `.spikes/` is not created merely because the user begins discussing a technical topic.

It is created or used only when Spike Execution Mode begins.

The project should normally contain:

```
/.spikes/
```

inside `.gitignore`.

This keeps experiments outside normal production version control unless the developer intentionally chooses otherwise.

---

# 17. SPIKE DIRECTORY NAMING

Default naming convention:

```
YYYYMMDD-[descriptive-slug]
```

Examples:

```
20260923-custom-carousel-element

20260923-go-sse-broadcast

20260923-sqlite-concurrent-writes
```

If multiple spikes share a slug:

```
20260923-go-sse-broadcast-02
```

The slug should describe what the spike proves rather than an entire application feature whenever practical.

---

# 18. STANDARD DIRECTORY STRUCTURE

Base structure:

```
.spikes/
└── 20260923-example/
    ├── spike.md
    ├── sandbox/
    └── evidence/
```

Required:

```
spike.md
sandbox/
```

Optional:

```
evidence/
```

---

# 19. SPIKE.MD

Every spike contains:

```
spike.md
```

This document preserves the reasoning necessary to understand and reproduce the spike.

Recommended structure:

```
# Spike: [Name]

## Problem

What technical problem are we solving?

## Proposed Approach

What solution is being tested?

## Objective

What must this spike demonstrate?

## Context

Why does the problem matter?

## Constraints

Relevant limitations.

## Execution Profile

Runtime/platform selected.

## Technologies / APIs

Relevant APIs, frameworks, protocols, or runtimes.

## Proof Criteria

What observable behavior determines success?

## Files

Description of the sandbox.

## Run

Commands needed to execute the spike.

## Observations

What happened?

## Result

PASS | FAIL | INCONCLUSIVE

## Production Implications

What did the spike teach us?

## Disposition

PROMOTE | KEEP | ABANDON | INCONCLUSIVE
```

---

# 20. SANDBOX DIRECTORY

`sandbox/` contains the actual self-contained solution.

Its contents depend on the selected execution profile.

Native Web:

```
sandbox/
├── index.html
├── component.js
└── styles.css
```

Go:

```
sandbox/
├── go.mod
├── main.go
└── main_test.go
```

Python:

```
sandbox/
├── main.py
└── test_main.py
```

Node:

```
sandbox/
├── package.json
├── spike.js
└── spike.test.js
```

Files and package manifests should only be introduced when they contribute to the spike.

---

# 21. EVIDENCE DIRECTORY

Optional:

```
evidence/
```

May contain:

* screenshots
* benchmark results
* logs
* traces
* JSON output
* sample responses
* profiling data
* fixture data
* test results

Evidence exists to support the conclusion.

It should not be generated solely for ceremony.

---

# 22. PRODUCTION CONTEXT BOUNDARY

Spike Lab may inspect existing production code as reference material.

By default:

```
production repository = READ ONLY

.spikes/             = READ / WRITE
```

Example:

Spike Lab may inspect:

```
src/components/carousel.js
src/styles/carousel.css
```

while writing to:

```
.spikes/20260923-carousel-pointer-events/
```

Production files should not be modified merely to create a spike.

---

# 23. TARGET BINDING

A developer may anchor discussion or a spike to:

* source files
* modules
* directories
* components
* APIs
* database schemas
* configuration
* architecture documents
* legacy code
* existing tests

Target binding gives the spike contextual reference.

It does not automatically grant permission to modify the target.

---

# 24. VALIDATION AND EXECUTION

When possible, Spike Lab should run or validate the solution using the platform's normal tooling.

Examples:

Native Web:

```
python3 -m http.server
```

JavaScript:

```
node spike.js
```

Bun:

```
bun run spike.js
```

Go:

```
go test ./...
go run .
```

Python:

```
python main.py
```

Ruby:

```
ruby spike.rb
```

Rails:

```
bin/rails test
```

Rust:

```
cargo test
cargo run
```

The amount of testing should be proportional to what needs to be proven.

A tiny API experiment should not automatically receive enterprise-scale test infrastructure.

---

# 25. RESULT CAPTURE

After execution, the agent records:

* whether the solution ran
* what behavior was observed
* whether proof criteria were satisfied
* limitations
* unexpected behavior
* implications for the real project

Possible result values:

```
PASS
```

The proposed solution was demonstrated successfully.

```
FAIL
```

The proposed solution did not satisfy the required behavior.

```
INCONCLUSIVE
```

The experiment did not provide enough evidence.

A failed spike is still valuable because it eliminates an approach.

---

# 26. SPIKE DISPOSITION

After evaluation, the spike may be marked:

## PROMOTE

The solution or concept should inform production implementation.

## KEEP

The spike is useful reference material.

## ABANDON

The approach has been rejected or is no longer useful.

## INCONCLUSIVE

Further investigation is required.

---

# 27. PROMOTION WORKFLOW

Promotion is separate from spike creation.

A spike should never be assumed to be production-quality code.

Before promoting a successful solution, the agent should consider:

* production architecture
* security
* authentication
* authorization
* observability
* failure handling
* configuration
* maintainability
* performance
* test coverage
* integration constraints
* deployment requirements

The production implementation may reuse concepts or code from the spike, but promotion should be deliberate.

---

# 28. EXAMPLE: NATIVE WEB SPIKE

Discussion:

```
Could CSS Scroll Snap replace our carousel library?
```

No files are created during this initial conversation.

Once the developer decides:

```
Let's prove it.
```

Spike Lab creates:

```
.spikes/
└── 20260923-native-scroll-carousel/
    ├── spike.md
    └── sandbox/
        ├── index.html
        ├── carousel.js
        └── styles.css
```

The spike demonstrates:

* snapping behavior
* keyboard interaction
* touch scrolling
* dynamic item sizing

The experiment answers whether the native browser solution is sufficient.

---

# 29. EXAMPLE: GO SPIKE

Discussion:

```
We may be able to use SSE instead of WebSockets.
```

The developer and agent discuss:

* communication direction
* reconnect behavior
* client requirements
* implementation complexity

No spike directory exists yet.

Once they decide to test the approach:

```
.spikes/
└── 20260923-go-sse-broadcast/
    ├── spike.md
    └── sandbox/
        ├── go.mod
        ├── main.go
        └── main_test.go
```

The spike proves whether:

* concurrent clients connect
* events broadcast correctly
* disconnects are cleaned up
* the standard library is sufficient

---

# 30. EXAMPLE: RAILS SPIKE

Discussion:

```
We are unsure how Turbo behaves when two streams update
the same target.
```

The agent may first explain expected behavior and inspect relevant code.

If execution would provide better evidence, the developer may proceed with a spike.

Spike:

```
.spikes/
└── 20260923-rails-turbo-ordering/
    ├── spike.md
    └── sandbox/
        ├── Gemfile
        ├── app/
        ├── config/
        └── test/
```

Because Rails behavior itself is under investigation, a small Rails environment is justified.

---

# 31. EXAMPLE: DATABASE SPIKE

Problem:

```
Can SQLite support the expected concurrent write pattern?
```

Proposed solution:

```
Use WAL mode with the application's expected write pattern.
```

Spike:

```
.spikes/
└── 20260923-sqlite-concurrent-writes/
    ├── spike.md
    ├── sandbox/
    │   ├── go.mod
    │   └── benchmark.go
    └── evidence/
        └── results.txt
```

The experiment exists only to prove or reject the database strategy.

It is not the application's persistence layer.

---

# 32. ANTI-PATTERNS

## Creating Files During Brainstorming

Bad:

Developer:

```
What are my options for realtime updates?
```

Agent immediately creates:

```
.spikes/realtime-app/
```

Better:

Discuss:

* SSE
* WebSockets
* polling
* requirements
* tradeoffs

Only create a spike once there is something concrete to prove.

---

## Building Before Understanding

Bad:

```
Build a realtime notification system.
```

Better:

First identify the uncertainty:

```
Can SSE satisfy our one-way realtime update requirements?
```

---

## Excessive Scaffolding

Bad:

Creating:

* frontend framework
* CSS framework
* database
* Docker
* authentication
* backend framework

just to test one browser API.

Better:

```
index.html
spike.js
```

---

## Technology Dogmatism

Bad:

```
All spikes must use vanilla JavaScript.
```

Better:

```
Use the environment that most directly proves the solution.
```

---

## Premature Productionization

Bad:

Adding production concerns before the approach itself has been proven.

Better:

First demonstrate that the underlying solution works.

---

## Treating the Spike as Production Code

A successful spike proves an approach.

It does not automatically prove that its exact implementation belongs in production.

---

## Endless Experimentation

Once the spike has answered its question, stop.

A new uncertainty should normally become a new discussion or a separate spike.

---

# 33. AGENT BEHAVIOR RULES

Spike Lab agents should follow these rules:

1. Discussion comes before execution.

2. Do not create files merely because a technical conversation begins.

3. Understand the problem before defining a spike.

4. Determine whether a spike is actually necessary.

5. Define what the spike must prove.

6. Keep each spike narrowly focused.

7. Make each spike self-contained.

8. Prefer executable evidence over prolonged speculation when a cheap experiment can resolve uncertainty.

9. Use the platform most appropriate to the problem.

10. Prefer native capabilities when they are sufficient.

11. Do not introduce frameworks without a reason.

12. Do not avoid frameworks when framework behavior is the problem.

13. Avoid unnecessary dependencies.

14. Keep production files read-only by default.

15. Record what was learned, not merely what files were generated.

16. Treat failed spikes as valid engineering outcomes.

17. Stop once the technical uncertainty has been resolved.

18. Do not quietly evolve a spike into a production implementation.

---

# 34. NON-FUNCTIONAL REQUIREMENTS

## Fast Startup

Spike execution should minimize setup overhead.

Native Web experiments should usually become runnable immediately after file generation.

Compiled languages may use their normal compiler workflow.

---

## Minimal Dependencies

Use only dependencies necessary to prove the approach.

Native Web spikes should normally require zero external dependencies.

Other platforms may use their normal ecosystems when relevant.

---

## Small Scope

A spike should contain only what is required to prove its solution.

There is no universal size limit because legitimate experiments vary significantly.

---

## Reproducibility

Another developer or AI agent should be able to inspect `spike.md`, execute the documented commands, and reproduce the experiment whenever practical.

---

## Isolation

Spike execution should not silently modify:

* production source
* production databases
* infrastructure
* deployment configuration
* external services
* secrets

---

## Portability

Spike artifacts should remain understandable independently of the AI system that generated them.

---

# 35. DESIGN PHILOSOPHY

Spike Lab follows:

```
Discuss before creating.

Understand before testing.

Problem before implementation.

Approach before scaffolding.

Small solution before large architecture.

Evidence before assumption.

Appropriate platform before technology preference.

Isolation before experimentation.

Proof before productionization.

Stop when the uncertainty is resolved.
```

---

# 36. FINAL PRODUCT DEFINITION

Spike Lab is a language- and platform-agnostic experimental laboratory for AI developer agents.

It supports technical discussion without automatically generating artifacts.

When discussion identifies a concrete solution or approach that should be proven, Spike Lab can transition into execution and create a small, isolated, self-contained spike.

A spike contains enough code and supporting material to independently understand, run, and evaluate the proposed solution.

Native Web technologies are preferred for browser-focused problems because they provide a low-friction execution environment.

They are not a universal constraint.

Go, Python, Ruby, Rails, Rust, C/C++, Node.js, databases, frameworks, infrastructure tools, and other platforms are valid when they provide the most direct way to prove the solution.

The defining workflow is:

```
DISCUSS
    ↓
UNDERSTAND
    ↓
DECIDE WHETHER A SPIKE IS NEEDED
    ↓
DEFINE THE SOLUTION TO PROVE
    ↓
CREATE SELF-CONTAINED SPIKE
    ↓
EXECUTE
    ↓
OBSERVE
    ↓
CONCLUDE
```

A Spike Lab conversation may end without creating any spike at all.

That is valid.

The spike workspace exists only when there is something concrete worth proving.

# 37. BROWSER CONTROL AND UI VALIDATION

For browser-based spikes, Spike Lab should actively discover whether the current agent environment provides browser-control capabilities.

The agent must not assume that a particular browser automation tool is installed.

Before executing a browser-based spike, the agent should inspect the tools available in the current environment.

Possible browser-control capabilities may include:

* MCP browser tools
* Chrome DevTools Protocol integrations
* Playwright-based MCP servers
* Puppeteer-based integrations
* browser-use tools
* agent-controlled Chrome instances
* agent-controlled Chromium instances
* desktop automation capable of controlling the system default browser
* IDE-provided browser preview or browser automation tools

If a compatible browser-control capability is available, Spike Lab should prefer using it for browser-oriented validation.

---

## 37.1 Capability Discovery

For UI or browser spikes, Spike Lab should determine:

```
Is browser control available?
    ↓
   YES
    ↓
use browser automation for execution and validation
```

or:

```
   NO
    ↓
use local serving + available browser workflow
    ↓
optionally suggest a compatible browser-control capability
```

The agent should inspect available tools rather than relying on a hardcoded browser integration.

This allows Spike Lab to operate across environments such as:

* Codex
* OpenCode
* Zed
* VS Code
* MCP-enabled coding agents
* desktop AI agents
* local terminal agents

---

## 37.2 Preferred Browser-Control Behavior

When browser automation is available, the agent may:

* start the spike's local server
* open the spike URL
* navigate between pages
* click controls
* type into forms
* trigger UI interactions
* inspect rendered output
* inspect browser console messages
* inspect network requests when supported
* resize the viewport
* test responsive behavior
* reload the application
* evaluate DOM state
* capture screenshots
* record observable failures
* repeat interaction sequences
* verify proof criteria

The browser-controlled validation should remain focused on the specific spike objective.

Spike Lab should not automatically create a large end-to-end test suite merely because browser automation exists.

---

## 37.3 Browser Selection

Spike Lab should prefer the most direct browser-control capability available.

Possible selection order:

```
dedicated MCP browser tool
    ↓
Chrome/Chromium DevTools integration
    ↓
Playwright/Puppeteer integration
    ↓
desktop browser automation
    ↓
system default browser
    ↓
manual browser instructions
```

The exact priority may vary based on available capabilities.

The agent should not unnecessarily install another browser if a usable browser already exists.

---

## 37.4 Chrome / Chromium

Chrome or Chromium is preferred when browser automation requires direct DevTools Protocol access or when the available MCP integration is Chrome-based.

A spike may be served locally, for example:

```
python3 -m http.server 8000 --directory sandbox
```

and then opened through the browser-control tool:

```
http://localhost:8000
```

The agent may then interact with the page and evaluate the spike's proof criteria.

---

## 37.5 Default Browser Support

If no dedicated Chrome or Chromium integration exists but the agent can control the operating system's default browser, that capability may be used instead.

Spike Lab should not require Chrome when another controllable browser can adequately prove the behavior being tested.

Browser choice should serve the experiment rather than become an unnecessary dependency.

---

## 37.6 Browser-Control Fallback

If no browser-control capability exists, Spike Lab should still be able to create the spike.

The fallback workflow is:

```
generate spike
    ↓
start local server if required
    ↓
provide local URL
    ↓
explain the minimal interaction needed to verify behavior
```

Example:

```
python3 -m http.server 8000 --directory sandbox
```

Then:

```
Open http://localhost:8000 in your browser.
```

The inability to automate browser interaction should not prevent creation of the spike itself.

---

## 37.7 Suggesting Browser-Control Capability

If browser automation would materially improve the spike and no suitable capability is present, the agent may recommend adding one.

Examples may include:

* a browser MCP server
* a Playwright MCP integration
* Chrome DevTools Protocol tooling
* Puppeteer integration
* an IDE browser-control extension
* a desktop automation capability

The agent should recommend capabilities generically unless the environment provides a specific supported integration.

It should not install software or modify the developer environment without permission.

---

## 37.8 Evidence Collection

When browser control is available, Spike Lab may store useful evidence under:

```
evidence/
```

Examples:

```
evidence/
├── initial-state.png
├── interaction-result.png
├── console.txt
└── observations.md
```

Evidence should only be captured when it helps demonstrate whether the spike succeeded.

Screenshots and logs are supporting evidence, not mandatory ceremony.

---

## 37.9 Browser Validation Example

Problem:

```
Can a native Custom Element implement the required
drag-and-drop interaction without a framework?
```

Spike Lab creates:

```
.spikes/
└── 20260923-native-drag-component/
    ├── spike.md
    ├── sandbox/
    │   ├── index.html
    │   ├── component.js
    │   └── styles.css
    └── evidence/
```

If browser automation is available, the agent may:

1. start a local server
2. open the page
3. drag the component
4. verify the resulting DOM state
5. resize the browser
6. repeat the interaction
7. inspect console errors
8. capture a screenshot
9. update `spike.md` with the result

This produces executable evidence rather than relying solely on source inspection.

---

# 38. ENVIRONMENT CAPABILITY SCAN

Before executing a spike, Spike Lab should inspect the current environment for capabilities relevant to the experiment.

Possible capabilities include:

* language runtimes
* compilers
* package managers
* browser-control tools
* MCP servers
* database clients
* containers
* local browsers
* test runners
* linters
* formatters
* HTTP clients
* filesystem tools

Spike Lab should reuse available capabilities before introducing new ones.

The environment scan should be lightweight and relevant to the current spike.

It should not indiscriminately probe every installed tool on the machine.

Example:

For a native browser spike, check for:

```
browser-control capability
local HTTP serving capability
JavaScript runtime if validation requires it
```

For a Go spike, check for:

```
go
```

For a PostgreSQL spike, check for:

```
psql or an appropriate database runtime
```

---

# 39. CAPABILITY-AWARE EXECUTION PRINCIPLE

Spike Lab follows:

> Discover first. Reuse second. Suggest third. Install only with permission.

In practical terms:

```
required capability
    ↓
already available?
   ↓       ↓
  YES      NO
   ↓        ↓
 use it   is an alternative available?
              ↓
           YES → use alternative
              ↓
            NO
              ↓
         suggest capability
              ↓
         install only if authorized
```

This principle applies to browsers, runtimes, compilers, package managers, databases, and other execution tools.

