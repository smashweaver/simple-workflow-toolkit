# Field Guide design system

Use this as the default visual language for a practical HTML guide. The bundled starter is the
concrete reference. Its specimen text teaches the components and must be replaced for a real guide.
The design originated in the HyperGo user guide; no HyperGo checkout is needed to use it.

## Palette

| Token | Value | Role |
| --- | --- | --- |
| `--paper` | `#f6f4ed` | Warm page background |
| `--surface` | `#fffef9` | Examples and inset reading areas |
| `--ink` | `#202e2b` | Main text |
| `--muted` | `#52635d` | Supporting text, still readable |
| `--line` | `#cdd4c8` | Quiet borders and separators |
| `--green` | `#214e3d` | Navigation, primary action, structural accents |
| `--soft` | `#e7eddf` | Orientation or principle callout |
| `--accent` | `#ba471f` | Section numbers, eyebrow labels, focus rings |

Favor color through type and a few intentional surfaces. Avoid gradients, decorative blobs, glass
panels, shadows on every card, or color coding that carries meaning without text. The default is a
light paper theme; do not add a theme switch unless it serves the requested guide.

## Type and space

- Main title and section headings: Georgia/Times serif, normal weight, tight tracking, compact line
  height. The serif provides character; preserve a restrained sans-serif for the reading body.
- Body: system sans-serif, about 17px with 1.65 line height. Supporting copy remains comfortably
  legible; small uppercase labels are accents, not the main information.
- Examples: monospace, around 15px, with preserved line breaks and wrapping for long paths or words.
- Desktop frame: up to 1600px wide; a roughly 256px contents rail and a flexible reading area.
  Long prose benefits from a narrower measure even when examples fill a two-column grid.
- Main title scales from approximately 48px to 82px; section titles from 32px to 43px. Adapt a long
  title rather than forcing the same line break on every viewport.
- Section spacing: about 54px with a thin divider; examples: 20–25px padding and 18px gaps.
  Border radii stay small (5–9px); pill shapes are reserved for filters.

These are defaults, not measurements to defend against real content. Prioritize readable line
lengths, hierarchy, and useful space over filling the viewport.

## Components and when they earn their place

| Component | Use |
| --- | --- |
| Brand + edition | Identify the guide; replace the specimen's name and initial |
| Contents rail | Orient a reader in a long guide; anchors remain ordinary links |
| Eyebrow + editorial title + introduction | State the subject and reader's next useful outcome |
| Primary anchor | Offer one useful jump, usually to the examples or first step |
| Principle callout | Establish the one framing idea readers need before acting |
| Numbered steps | Explain a sequence where order matters |
| Example card | Pair an action/request with inputs and expected outcome |
| Copy control | Copy an exact example; retain visible text and failure feedback |
| Comparison columns | Explain two responsibilities or alternatives |
| Review list | Make acceptance criteria or observations scannable |
| Details/summary | Hold supplementary explanations, not essential instructions |

Use flowing prose and section dividers for the main narrative. A page made entirely of cards loses
the reading rhythm. Do not add navigation, filters, or a large hero to a one-paragraph answer.

## Responsive and accessible behavior

The starter collapses example columns before the text becomes cramped, then turns the rail into
normal top-of-page navigation below 700px. Preserve document reading order. Use visible focus rings,
a skip link, descriptive labels, and comfortable controls (roughly 44px tall). No hover-only content.

All content is present in the HTML. Enhancement controls start hidden until their handlers exist;
without JavaScript, the guide remains complete. Filter state uses `aria-pressed`; result counts and
copy feedback use status announcements. Print CSS shows every example and hides controls. The starter
also opens details before printing and restores the reader's previous state afterwards, with a CSS
fallback for JavaScript-disabled printing. Check long links, headings, tables, and examples at a narrow
viewport. Report the browsers and conditions actually checked.

## Adaptation boundary

Carry the visual language into the new subject. Do not carry HyperGo's product rules, names, local
paths, release status, or approval wording into an unrelated guide. Likewise, retain the receiving
project's existing privacy and publication rules instead of replacing them with defaults from a sample.
