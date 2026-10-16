---
name: field-guide
description: Create or restyle standalone HTML user guides, onboarding documents, handbooks, and practical explainers with a warm paper-and-green editorial design. Use when the user wants documentation people can browse, act on, print, or use for copyable examples, including the style of the HyperGo HTML user guide. Preserve source meaning when adapting existing material. Prefer a simple converter for a literal Markdown preview; this skill is for authored guides, not application interfaces, dashboards, or marketing sites.
---

# Field Guide

Make information easy to read and act on. Deliver a self-contained HTML guide with a clear reading
order, concrete examples, and restrained interactions. The default design is warm paper, deep green,
serif headings, quiet borders, and generous space, derived from the HyperGo user guide.

## Ground the guide

Read the supplied material and relevant project instructions. Identify the reader, what they want
to do, what they already know, and the outcome the guide should help them reach. Infer routine
presentation choices; ask only when missing information blocks useful work.

Preserve the source's facts, qualifications, unresolved decisions, and approval boundaries. Label
illustrative content as examples. Do not turn a design into a claim of working software, or invent
policies to complete a guide. An HTML deliverable does not require migrating the source documents.

## Shape the reading experience

Choose sections around the reader's questions or actions. A useful progression is orientation →
first step → worked examples → reviewing the result → returning later. Use only what the subject
needs; do not force a fixed number of sections or cards.

Write for the reader rather than the system's internal structure. Pair a concrete request or action
with what to provide and what to expect. Keep explanatory prose in flowing sections; reserve cards
for genuinely parallel examples and comparisons. Add a contents rail when the guide is long enough
to benefit from navigation. Use a short header for a short guide.

## Build in the field-guide style

Read [the design system](references/design-system.md), then inspect and adapt
[the HTML starter](assets/field-guide.html). Copy it into the user's destination and edit that copy;
leave the installed starter intact. It is a working visual specimen, not a template engine.
Replace its specimen content, title, description, brand initial, navigation, and links. Remove unused
sections and controls. The asset carries the actual CSS and interaction code, so reuse them instead
of approximating the style from this description.

Preserve a supplied brand or explicit style choice. Otherwise retain the default palette, type
hierarchy, restrained spacing, and editorial character. Keep styles and any necessary JavaScript
inline, use system fonts, and embed small icons. Avoid runtime CDN calls, external fonts, analytics,
framework scaffolding, or build steps for an ordinary document. Use an existing site's structure
when the user explicitly asks to integrate into that site.

## Add useful interactions only

The starter's copy buttons copy text; they never submit it or execute commands. Clipboard access can
fail, especially in local files: keep the manual-selection fallback and honest status message.
If examples contain shell commands, make their effects clear in the surrounding explanation.

Filters are optional for a collection large enough to benefit. The starter demonstrates their wiring;
remove them for a short set of examples. Use ordinary links for navigation and native details/summary
for supplementary explanation. Content must remain readable without JavaScript. A filter must not
silently omit content when the guide is printed. Ensure collapsed details are also included in print.

## Check and hand off

Check headings, unique IDs, anchor/file targets, page title, and removal of irrelevant specimen text.
When adapting sources, review the result for omitted qualifications and unsupported claims.
Validate any changed JavaScript syntax. Use available browser tools to inspect desktop and narrow
mobile layouts, keyboard navigation, copy success and failure, and any filters. Check reading with
JavaScript disabled and the print layout when those behaviors are included. Visually inspect the
result; absence of overflow alone does not establish good typography or usable controls.

Try direct local-file use where the browser tool permits it. If the tool blocks file URLs, preview
over loopback and state that limit. Report unavailable checks without claiming they passed. Do not
install browser dependencies or choose paid services merely to produce a document unless authorized.

Deliver the HTML at the requested path, or in the owning project's documentation directory. If there
is no project or destination, use a named temporary output folder and report it. Link the artifact
and summarize what was checked. Update an existing index/README when the guide belongs in a project.
Follow the project's commit and publication rules; creating a guide is not permission to publish it.
