# Proposal: a portable cinematic-video skill

> **Status:** Draft for Jason's review; not approved for implementation.
> **Purpose:** Decide whether repeated HyperGo-lab video production should become a reusable, standalone skill.
> **Owner:** Jason.

## Summary

Create an optional, portable `cinematic` skill for turning an inspectable source—such as an Archify explainer, static HTML presentation, or running application—into a narrated, timed video. The skill should guide the story, cue sheet, capture, audio/video assembly, and verification. It should not copy either article's renderer or bundle Archify, Playwright, a text-to-speech provider, or FFmpeg.

Start instruction-only. Reconsider shared scripts only after another production proves the same interfaces and failure checks recur.

## Context and evidence

Two local HyperGo-lab packages independently contain `scripts/render_movie.mjs`:

- `articles/20261110-hypergo-app-lifecycle-solo-developer-survival/` captures an Archify lifecycle presentation, follows its `routeProbe` journey, and synchronizes actions with narration cues.
- `articles/20261112-hypergo-devreload-zero-npm-reactivity/` captures a standalone HTML presentation and calls page-specific JavaScript functions on its cue schedule.
- Both scripts use a browser recording, narration audio, and FFmpeg muxing path to produce MP4 output. Each also owns its page controls, scene cues, and duration.
- The Nov 12 renderer catches and suppresses page-action errors, so a render can continue after a cue fails. A reusable workflow should make failed cues visible and stop or clearly mark the output invalid.

The current HyperGo skill already gives general reel guidance in `skills/hypergo/references/diagrams-and-reels.md`: narrative, audience, capture, output ownership, and review. This proposal covers the more detailed repeatable movie-production workflow. It follows D-48's boundary: HyperGo may coordinate reel requests, but Archify and any media renderer remain external tools rather than framework dependencies.

Evidence is limited to two source packages and their scripts. The MP4s were not independently replayed or checked as part of this proposal review; the scripts' existence does not establish export quality or successful reproducibility.

## Proposed skill contract

The skill should:

1. **Inspect inputs and constraints.** Identify the audience, source stage, source controls, privacy and licensing limits, available tools, requested duration, and publication boundary. Distinguish observed application behavior from staged or proposed scenes.
2. **Shape the story.** Produce an editable storyboard, voiceover, and cue sheet. Cues should reference explicit source controls or documented selectors, not assume that generic keyboard input changes the view.
3. **Select a production path.** Reuse the project's own capture tools when suitable; otherwise use available browser/video tooling. Use Archify when it fits and is installed, without requiring or vendoring it. Audio may be supplied or synthesized through an available provider; do not hard-code a provider or promise availability.
4. **Render reproducibly.** Keep scripts, timing, dependencies, source references, and output beside the owning project artifact. State any required external service, credentials, browser, codec, or local binary before rendering.
5. **Verify the export.** Check that cues succeeded, the narration is not clipped, audio and scenes remain aligned, the video plays, dimensions and duration match the request, and representative frames are readable. Report unrun checks; a successful render command alone is not verification.
6. **Respect approval boundaries.** Do not publish, upload, contact an audience, or expose private material without explicit authorization. Keep customer-specific source and evidence in the owning application repository.

## Ownership and boundaries

- Install as a standalone skill, proposed path `skills/cinematic/SKILL.md`; keep it usable without SWT or HyperGo.
- Leave HyperGo's `diagrams-and-reels.md` as the framework-facing entry point. It can refer to the cinematic skill when the user asks for a narrated video, while simple diagrams and walkthroughs continue using their existing paths.
- Keep article text, source-specific cue functions, generated audio, raw recordings, and final video with the article or application that owns them.
- Do not move the existing movie packages or turn their private scripts into framework assets as part of this proposal.
- Do not make a universal renderer, install dependencies, or add a command in the first slice. The skill may explain how to adapt an existing local renderer.

## Validation plan if approved

Before implementation, prepare a bounded task record and preserve the existing packages. Then validate the skill guidance against:

1. The Archify lifecycle presentation and its route journey.
2. The standalone DevReload HTML and its `showStep` controls.
3. A third, materially different source, such as a safe synthetic application walkthrough, to test whether the instructions generalize beyond two sibling packages.

Use short, non-public test outputs. Include a negative control where a requested page action fails; the workflow must not report a valid finished video. Inspect actual playback and frames, not only source code or media metadata. Keep each test's output and detailed evidence in its owning project or a disposable local workspace.

Acceptance should require standalone skill validation, resolved internal links, a successful end-to-end render for each accepted path, visible failure on the negative control, checked audio/video alignment and readability, and honest reporting of provider/tool limits. If only one path proves viable, narrow the skill rather than claiming support for all three.

## Risks and alternatives

| Option | Benefit | Cost or risk |
|---|---|---|
| Keep only HyperGo's current reel guidance | No new skill to maintain; sufficient for occasional one-off requests. | Repeated timing, capture, mux, and output-check work remains project-specific. |
| Add a portable cinematic skill (recommended) | Reuses a demonstrated workflow while keeping project controls and media local. | Two examples may not prove the process generalizes; end-to-end checks need external tools. |
| Build a shared renderer now | Could reduce duplicate script code. | Premature abstraction across two different page-control APIs; creates dependencies and maintenance before a stable interface is known. |

## Owner decision requested

Decide whether to authorize a bounded skill-authoring task using the contract and validation plan above. This proposal does not authorize implementation, dependency installation, moving existing artifacts, or publication.
