---
name: "swt:think"
description: Base behavioral guidelines for AI agent reasoning. Use when handling non-coding tasks (swt:digest, swt:task, swt:spec, swt:init, swt:commit, AGENTS.md generation). Coding-specific tasks should use swt:code which inherits from this skill.
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# Thinking Guidelines

Base behavioral guidelines for AI agent reasoning, derived from `swt:code` principles. Apply to all non-coding tasks: session digests, task management, specs, workspace initialization, commit messages, and documentation generation.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Responding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before responding:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Brevity First

**Minimum output that solves the problem. Nothing speculative.**

- No sections beyond what was asked.
- No abstractions for single-use content.
- No "flexibility" or "configurability" that wasn't requested.
- No elaboration for already-clear concepts.
- If you write 200 words and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Focused Responses

**Touch only what you must. Clean up only your own mess.**

When working with existing files:
- Don't "improve" adjacent sections, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated content, mention it — don't delete it.

When your changes create orphans:
- Remove sections/variables that YOUR changes made unused.
- Don't remove pre-existing unused content unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Clear Success Criteria

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Summarize session" → "Capture key outcomes, decisions, and task states in digest"
- "Create task file" → "Write task.md with valid naming, proper template, user confirmation"
- "Generate spec" → "Produce SPEC.md with objectives, requirements, and scenarios"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Structural Changes & Manual Consent
 
 **The Locked Gate: Manual consent overrides all automation.**
 
 Before executing any **Structural Change** (directory creation, git initialization, major refactoring, or initialization of new project skeletons):
 1. **Halt execution.** Do not proceed even if the tool/system says "auto-approved".
 2. **Verify Phase 0 Ritual**: Ensure a Scenario-Based Brainstorming (A, B, C) has occurred in the chat history for this specific change.
 3. **Request Manual "Go"**: Explicitly ask the user for a verbal "Go" or "Approved" in the chat.
 4. **Identify the Gate**: State clearly: *"I am at a Locked Gate. This change is structural. Do I have your approval to proceed?"*
 
 **Failure to halt at a Locked Gate is a critical protocol violation.**
 
 ---

## Companion Skills

These guidelines are the **base layer** for all SWT generation skills:

- **`swt:code`** — Coding-specific specialization of these principles (Phase 5-7 of workflow)
- **`swt:digest`** — Session summaries and milestones
- **`swt:task`** — Task file lifecycle management
- **`swt:spec`** — Feature specification generation
- **`swt:init`** — Workspace bootstrap and AGENTS.md generation
- **`swt:commit`** — Diff analysis and commit message drafting

All inherit from `swt:think`. Load this skill first when handling non-coding reasoning tasks.
