#!/usr/bin/env python3
"""Refactor a markdown document into a self-contained HTML artifact.

Standard library only. Output has zero external references: no CDN links,
no webfonts, no JavaScript. Works offline from file:// forever.
"""

import argparse
import html
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import diagrams

DIAGRAM_MARKER = "<!--htmlify-diagram:{index}-->"

CSS = """
:root {
  --bg: #ffffff; --fg: #1a1a1a; --muted: #6b7280; --rule: #e5e7eb;
  --code-bg: #f6f8fa; --accent: #0969da; --quote: #f0f4f8;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #0d1117; --fg: #e6edf3; --muted: #8b949e; --rule: #30363d;
    --code-bg: #161b22; --accent: #4493f8; --quote: #161b22;
  }
}
* { box-sizing: border-box; }
body {
  margin: 0 auto; padding: 3rem 1.5rem 6rem; max-width: 46rem;
  background: var(--bg); color: var(--fg);
  font: 16px/1.65 -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
}
h1, h2, h3, h4, h5, h6 { line-height: 1.25; margin: 2rem 0 1rem; font-weight: 600; }
h1 { font-size: 2rem; margin-top: 0; padding-bottom: .5rem; border-bottom: 1px solid var(--rule); }
h2 { font-size: 1.5rem; padding-bottom: .3rem; border-bottom: 1px solid var(--rule); }
h3 { font-size: 1.2rem; }
p, ul, ol, blockquote, pre, table { margin: 0 0 1rem; }
a { color: var(--accent); text-decoration: none; }
a:hover { text-decoration: underline; }
ul, ol { padding-left: 1.5rem; }
li { margin: .25rem 0; }
li > ul, li > ol { margin: .25rem 0; }
code {
  background: var(--code-bg); padding: .15em .4em; border-radius: 4px;
  font-family: ui-monospace, "SFMono-Regular", Menlo, Consolas, monospace;
  font-size: .9em;
}
pre {
  background: var(--code-bg); border: 1px solid var(--rule); border-radius: 6px;
  padding: 1rem; overflow-x: auto;
}
pre code { background: none; padding: 0; font-size: .85em; }
blockquote {
  background: var(--quote); border-left: 3px solid var(--rule);
  margin-left: 0; padding: .5rem 1rem; color: var(--muted);
}
blockquote > :last-child { margin-bottom: 0; }
hr { border: 0; border-top: 1px solid var(--rule); margin: 2rem 0; }
table { border-collapse: collapse; width: 100%; font-size: .95em; }
th, td { border: 1px solid var(--rule); padding: .5rem .75rem; text-align: left; }
th { background: var(--code-bg); font-weight: 600; }
img { max-width: 100%; }
.diagram {
  margin: 0 0 1.25rem; padding: 1rem; overflow-x: auto;
  border: 1px solid var(--rule); border-radius: 6px; background: var(--code-bg);
}
/* Each SVG is pinned to its natural width at generation time, so a wide
   diagram scrolls instead of being scaled down into illegibility. */
.diagram svg { display: block; max-width: none; height: auto; }
.diagram-dark { display: none; }
@media (prefers-color-scheme: dark) {
  .diagram-light { display: none; }
  .diagram-dark { display: block; }
}
"""


def escape(text):
    return html.escape(text, quote=False)


def inline(text):
    """Render inline markdown. Code spans are extracted first so their
    contents are never re-processed."""
    spans = []

    def stash(match):
        spans.append(match.group(1))
        return f"\x00{len(spans) - 1}\x00"

    text = re.sub(r"`([^`]+)`", stash, text)
    text = escape(text)

    text = re.sub(r"!\[([^\]]*)\]\(([^)\s]+)\)", r'<img src="\2" alt="\1">', text)
    text = re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", r'<a href="\2">\1</a>', text)
    text = re.sub(r"\*\*\*(.+?)\*\*\*", r"<strong><em>\1</em></strong>", text)
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])", r"<em>\1</em>", text)
    text = re.sub(r"~~(.+?)~~", r"<del>\1</del>", text)

    for index, raw in enumerate(spans):
        text = text.replace(f"\x00{index}\x00", f"<code>{escape(raw)}</code>")
    return text


def split_row(line):
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def is_divider(line):
    return bool(re.fullmatch(r"\s*\|?[\s:|-]+\|?\s*", line)) and "-" in line


def render_table(rows):
    head, *body = rows
    out = ["<table>", "<thead><tr>"]
    out += [f"<th>{inline(c)}</th>" for c in head]
    out.append("</tr></thead><tbody>")
    for row in body:
        out.append("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in row) + "</tr>")
    out.append("</tbody></table>")
    return "".join(out)


ITEM = re.compile(r"^(\s*)([-*+]|\d+)\.\s+(.*)$|^(\s*)([-*+])\s+(.*)$")
# Groups: (indent, num, text) for ordered, (indent, -, text) for unordered.
GROUP = {(1, 2, 3), (4, 5, 6)}
TASK = re.compile(r"^\[([ xX])\]\s+(.*)$")
FRONTMATTER = re.compile(r"\A---\n(.*?)\n---\n", re.DOTALL)


def strip_frontmatter(markdown):
    """Remove a leading YAML frontmatter block, returning it for title lookup."""
    match = FRONTMATTER.match(markdown)
    if not match:
        return "", markdown
    return match.group(1), markdown[match.end():]


def item_of(line):
    match = ITEM.match(line)
    if not match:
        return None
    for indent_g, marker_g, text_g in GROUP:
        if match.group(marker_g) is not None:
            marker = match.group(marker_g)
            ordered = marker.isdigit()
            return {
                "indent": len(match.group(indent_g)),
                "ordered": ordered,
                "number": int(marker) if ordered else None,
                "text": match.group(text_g),
            }
    return None


def build_nodes(items, index, indent):
    """Collect sibling items at exactly `indent`, recursing into children."""
    nodes = []
    while index < len(items):
        node = item_of(items[index])
        if node is None or node["indent"] < indent:
            break
        index += 1
        if node["indent"] > indent:
            if nodes:
                child, index = build_nodes(items, index, node["indent"])
                nodes[-1]["children"].extend(child)
            continue
        node["children"] = []
        nodes.append(node)
        if index < len(items):
            following = item_of(items[index])
            if following and following["indent"] > indent:
                node["children"], index = build_nodes(items, index, following["indent"])
    return nodes, index


def render_list(nodes):
    ordered = nodes[0]["ordered"]
    tag = "ol" if ordered else "ul"
    start_attr = f' start="{nodes[0]["number"]}"' if ordered and nodes[0]["number"] != 1 else ""
    out = [f"<{tag}{start_attr}>"]
    for node in nodes:
        task = TASK.match(node["text"])
        if task:
            checked = " checked" if task.group(1) in "xX" else ""
            body = f'<input type="checkbox" disabled{checked}> {inline(task.group(2))}'
        else:
            body = inline(node["text"])
        nested = render_list(node["children"]) if node["children"] else ""
        out.append(f"<li>{body}{nested}</li>")
    out.append(f"</{tag}>")
    return "".join(out)


def render(markdown, collect=None):
    if not isinstance(markdown, str):
        markdown = "\n".join(markdown)
    lines = markdown.replace("\r\n", "\n").split("\n")
    out = []
    index = 0

    while index < len(lines):
        line = lines[index]

        if not line.strip():
            index += 1
            continue

        fence = re.match(r"^ {0,3}(`{3,}|~{3,})\s*(\S+)?", line)
        if fence:
            marker, lang = fence.group(1)[0], fence.group(2) or ""
            index += 1
            body = []
            # A closing fence is the same character, at least as long, with no
            # info string. A nested ```bash inside a ```markdown block is
            # literal content, not a close.
            closing = re.compile(rf"^ {{0,3}}{re.escape(marker)}{{{len(fence.group(1))},}}\s*$")
            while index < len(lines) and not closing.match(lines[index]):
                body.append(lines[index])
                index += 1
            index += 1
            cls = f' class="language-{escape(lang)}"' if lang else ""
            source = chr(10).join(body)
            if diagrams.is_diagram(lang, body):
                fallback = f"<pre><code{cls}>{escape(source)}</code></pre>"
                if collect is not None:
                    collect.append(source)
                    out.append(DIAGRAM_MARKER.format(index=len(collect) - 1))
                else:
                    out.append(fallback)
                continue
            out.append(f"<pre><code{cls}>{escape(source)}</code></pre>")
            continue


        heading = re.match(r"^(#{1,6})\s+(.*)$", line)
        if heading:
            level = len(heading.group(1))
            out.append(f"<h{level}>{inline(heading.group(2).strip())}</h{level}>")
            index += 1
            continue

        if re.fullmatch(r"\s*([-*_])\s*\1\s*\1[\s\-*_]*", line):
            out.append("<hr>")
            index += 1
            continue

        if line.lstrip().startswith(">"):
            body = []
            while index < len(lines) and lines[index].lstrip().startswith(">"):
                body.append(re.sub(r"^\s*>\s?", "", lines[index]))
                index += 1
            out.append(f"<blockquote>{render(body)}</blockquote>")
            continue

        if line.lstrip().startswith("|") and index + 1 < len(lines) and is_divider(lines[index + 1]):
            rows = [split_row(line)]
            index += 2
            while index < len(lines) and lines[index].lstrip().startswith("|"):
                rows.append(split_row(lines[index]))
                index += 1
            out.append(render_table(rows))
            continue

        if item_of(line):
            body = []
            while index < len(lines):
                current = lines[index]
                if not current.strip():
                    following = item_of(lines[index + 1]) if index + 1 < len(lines) else None
                    previous = item_of(body[-1]) if body else None
                    if not following or (previous and following["indent"] <= previous["indent"]):
                        break
                    index += 1
                    continue
                if not item_of(current) and not current.startswith((" ", "\t")):
                    break
                body.append(current)
                index += 1
            nodes, _ = build_nodes(body, 0, item_of(body[0])["indent"])
            out.append(render_list(nodes))
            continue

        body = []
        while index < len(lines) and lines[index].strip():
            breakable = (
                lines[index].startswith("#")
                or lines[index].lstrip().startswith((">", "|", "-", "*", "+"))
                or re.match(r"^\s*\d+\.\s+", lines[index])
                or re.match(r"^(`{3,}|~{3,})", lines[index])
            )
            if breakable and body:
                break
            body.append(lines[index])
            index += 1
        out.append(f"<p>{inline(' '.join(body))}</p>")

    return "\n".join(out)


def build(title, body):
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{escape(title)}</title>
<style>{CSS}</style>
</head>
<body>
{body}
</body>
</html>
"""


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", help="Markdown file, or - for stdin")
    parser.add_argument("-o", "--out", help="Output path (default: <source>.html)")
    parser.add_argument("--stdout", action="store_true", help="Print HTML instead of writing a file")
    parser.add_argument("--no-diagrams", action="store_true", help="Leave mermaid blocks as code")
    args = parser.parse_args()

    if args.source == "-":
        markdown = sys.stdin.read()
        source = Path.cwd() / "document.md"
    else:
        source = Path(args.source).expanduser().resolve()
        if not source.is_file():
            sys.exit(f"error: no such file: {source}")
        markdown = source.read_text(encoding="utf-8")

    frontmatter, markdown = strip_frontmatter(markdown)

    title = next(
        (m.group(2).strip() for m in (re.match(r"^(#{1,6})\s+(.*)$", ln) for ln in markdown.split("\n")) if m),
        None,
    )
    if not title:
        declared = re.search(r"^title:\s*(.+)$", frontmatter, re.MULTILINE)
        title = declared.group(1).strip().strip("\"'") if declared else source.stem

    sources = []
    body = render(markdown, collect=sources if not args.no_diagrams else None)

    if sources:
        rendered = diagrams.render(sources)
        if rendered:
            for index, (light, dark) in enumerate(rendered):
                body = body.replace(
                    DIAGRAM_MARKER.format(index=index),
                    f'<figure class="diagram diagram-light">{light}</figure>'
                    f'<figure class="diagram diagram-dark">{dark}</figure>',
                )
        else:
            body = re.sub(
                DIAGRAM_MARKER.format(index=r"(\d+)"),
                lambda m: f'<pre><code class="language-mermaid">{escape(sources[int(m.group(1))])}</code></pre>',
                body,
            )
            print(f"note: {len(sources)} diagram(s) left as code blocks", file=sys.stderr)

    document = build(title, body)

    if args.stdout:
        sys.stdout.write(document)
        return

    out = Path(args.out).expanduser() if args.out else source.with_suffix(".html")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(document, encoding="utf-8")
    print(out)


if __name__ == "__main__":
    main()
