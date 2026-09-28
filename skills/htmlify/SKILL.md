---
name: htmlify
description: Refactor a markdown document into a self-contained HTML artifact, then optionally open it in the default browser. Use when the user says "htmlify", "preview this markdown", "open this md in my browser", "render this doc as HTML", or wants a markdown file viewable as a single portable file. Standard library only, no network fetches, no JavaScript.
user-invocable: true
allowed-tools:
  - Bash
  - Read
---

# htmlify — Markdown to Self-Contained HTML

The deliverable is a **file**, not a browser window. A `.md` file is hard to
read in a terminal; htmlify converts it to one `.html` file that opens
correctly from `file://`, offline, forever.

## Contract

Three properties define success. Verify all three:

1. **Self-contained** — one file. No CDN links, no webfonts, no JavaScript, no
   sibling assets. `grep -E 'src="http|<script|<link'` on the output returns
   nothing. Diagrams are pre-rendered to inline SVG at generation time, so
   they add no runtime dependency either.
2. **Correct** — headings, lists (including nested and task lists), tables,
   blockquotes, fenced code, rules, and inline emphasis/links/images render as
   HTML. All text is escaped, so source markdown containing `<script>` cannot
   execute.
3. **Predictable location** — output sits beside the source as
   `<source>.html` unless `-o` says otherwise. The user must be able to find,
   re-generate, commit, or share it without guessing.

## Usage

```bash
uv run --no-project python <skill>/scripts/htmlify.py <file.md>            # writes <file>.html
uv run --no-project python <skill>/scripts/htmlify.py <file.md> -o out.html
uv run --no-project python <skill>/scripts/htmlify.py <file.md> --stdout   # print, write nothing
uv run --no-project python <skill>/scripts/htmlify.py <file.md> --no-diagrams
cat file.md | uv run --no-project python <skill>/scripts/htmlify.py -      # stdin
```

Always invoke Python through `uv run --no-project`. The script prints the
output path on success. Report that path to the user.

## Diagrams

Mermaid blocks are detected by an explicit ` ```mermaid ` fence, or by a bare
fence whose first line starts a diagram keyword (`graph`, `flowchart`,
`sequenceDiagram`, `classDiagram`, and friends).

They are rendered to static SVG **during generation** and embedded inline, in
both light and dark themes. The stylesheet shows the matching one via
`prefers-color-scheme` — no JavaScript, no CDN. This is what the archived
`swt:flow` renderer could not do: it imported mermaid from a CDN at view time,
which broke self-containment and rendered nothing offline.

Build-time requirements, both cached in `~/.cache/htmlify/`:

- **mermaid 11.4.1**, downloaded once on first use that needs it. Delete
  `~/.cache/htmlify/mermaid.min.js` to force a refresh.
- **A Chrome/Chromium binary**, driven headless. Auto-detected from
  `google-chrome`, `google-chrome-stable`, `chromium`, `chromium-browser`.
  Override with `CHROME_BIN=/path/to/chrome`.

If either is missing, or a diagram fails to parse, rendering **degrades
softly**: the block stays a code block, a warning goes to stderr, and the rest
of the document still converts. Never let a bad diagram abort the run. Use
`--no-diagrams` to skip the Chrome launch deliberately.

Cost: roughly 1 second when diagrams are present, near-instant when they are
not — documents with no charts never start a browser.

## Opening in the browser

Optional, and only when asked. The artifact is complete without it.

```bash
if command -v xdg-open >/dev/null 2>&1; then xdg-open "<path>" >/dev/null 2>&1 &
elif command -v firefox >/dev/null 2>&1; then firefox "<path>" >/dev/null 2>&1 &
elif command -v google-chrome >/dev/null 2>&1; then google-chrome "<path>" >/dev/null 2>&1 &
elif command -v chromium >/dev/null 2>&1; then chromium "<path>" >/dev/null 2>&1 &
fi
```

Always background it (`&`) so the agent does not block. If no launcher
exists, say so and hand over the path.

## Scope

Supports: ATX headings, paragraphs, bold/italic/strikethrough, inline code,
links, images, ordered/unordered/nested/task lists, blockquotes, pipe tables,
horizontal rules, fenced code with language class, YAML frontmatter (stripped;
`title:` used as the document title), mermaid diagrams as inline SVG.

Out of scope: Setext headings, reference-style links, footnotes, task-list
interactivity (checkboxes render disabled). Do not add these without being
asked.

## Rules

- Regenerate rather than hand-edit an artifact. If the user wants a change in
  the output, fix the markdown or the script, not the HTML.
- Never introduce a JavaScript dependency to make the page interactive. The
  self-contained property is the whole point. If a feature seems to need JS,
  it belongs at generation time instead — that is how diagrams are handled.
- Escaping is already handled. If content renders as visible `<script>` text,
  that is correct behavior, not a bug to "fix" by stripping the content.
- Multiple documents means multiple invocations. Do not concatenate sources.
