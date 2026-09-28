"""Build-time diagram rendering: mermaid source -> inline SVG.

Diagrams are rendered during generation and embedded as static SVG, so the
finished artifact needs no JavaScript and no network at view time. Both color
themes are rendered and the stylesheet picks one via prefers-color-scheme.

Requires a local Chrome/Chromium binary to drive headless. If anything is
missing, rendering fails softly and the caller keeps the original code block.
"""

import functools
import http.server
import json
import os
import re
import shutil
import socket
import subprocess
import sys
import threading
import urllib.request
from pathlib import Path

MERMAID_VERSION = "11.4.1"
MERMAID_URL = f"https://cdn.jsdelivr.net/npm/mermaid@{MERMAID_VERSION}/dist/mermaid.min.js"
CACHE_DIR = Path.home() / ".cache" / "htmlify"
MERMAID_JS = CACHE_DIR / "mermaid.min.js"

CHROME_CANDIDATES = ("google-chrome", "google-chrome-stable", "chromium", "chromium-browser")

DIAGRAM_TYPES = (
    "graph", "flowchart", "sequenceDiagram", "classDiagram", "stateDiagram",
    "stateDiagram-v2", "erDiagram", "journey", "gantt", "pie", "gitGraph",
    "mindmap", "timeline", "quadrantChart", "requirementDiagram", "C4Context",
    "block-beta", "sankey-beta", "xychart-beta",
)

HARNESS = """<!DOCTYPE html>
<html><head><meta charset="utf-8"></head><body>
<script type="application/json" id="payload">__PAYLOAD__</script>
<script src="/mermaid.min.js"></script>
<script>
(async () => {
  const jobs = JSON.parse(document.getElementById('payload').textContent);
  const results = [];
  for (const job of jobs) {
    try {
      mermaid.initialize({ startOnLoad: false, theme: job.theme, securityLevel: 'strict' });
      const { svg } = await mermaid.render('g' + results.length, job.source);
      results.push(svg);
    } catch (error) {
      results.push('__HTMLIFY_DIAGRAM_ERROR__' + String(error));
    }
  }
  document.body.innerHTML = results.join('__HTMLIFY_DIAGRAM_SPLIT__');
})();
</script></body></html>
"""

SPLIT = "__HTMLIFY_DIAGRAM_SPLIT__"
FAILED = "__HTMLIFY_DIAGRAM_ERROR__"


def is_diagram(lang, body):
    """True when a fenced block should be treated as a diagram."""
    if lang in ("mermaid", "graph", "flow", "diagram"):
        return True
    if lang:
        return False
    first = next((line.strip() for line in body if line.strip() and not line.strip().startswith("%%")), "")
    return any(first.startswith(kind) for kind in DIAGRAM_TYPES)


def find_chrome():
    override = os.environ.get("CHROME_BIN")
    if override and (shutil.which(override) or Path(override).exists()):
        return override
    return next((found for name in CHROME_CANDIDATES if (found := shutil.which(name))), None)


def ensure_mermaid():
    """Download the mermaid bundle once and cache it. Returns its path."""
    if MERMAID_JS.exists() and MERMAID_JS.stat().st_size > 100_000:
        return MERMAID_JS
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(MERMAID_URL, timeout=120) as response:
        payload = response.read()
    if len(payload) < 100_000:
        raise RuntimeError("mermaid bundle download looks truncated")
    MERMAID_JS.write_bytes(payload)
    return MERMAID_JS


@functools.lru_cache(maxsize=1)
def _quiet_handler():
    class Handler(http.server.SimpleHTTPRequestHandler):
        def log_message(self, *args):
            pass

    return Handler


@functools.lru_cache(maxsize=1)
def _serve(directory):
    """Start a throwaway static server on localhost; returns the port."""
    with socket.socket() as probe:
        probe.bind(("127.0.0.1", 0))
        port = probe.getsockname()[1]
    handler = functools.partial(_quiet_handler(), directory=str(directory))
    server = http.server.ThreadingHTTPServer(("127.0.0.1", port), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return port


def render(sources, timeout=180):
    """Render mermaid sources to (light_svg, dark_svg) pairs.

    Returns None if diagrams cannot be produced at all, so the caller can fall
    back to leaving the code blocks untouched.
    """
    if not sources:
        return []

    try:
        ensure_mermaid()
    except Exception as error:  # noqa: BLE001 - any failure must degrade to a code block
        print(f"warning: mermaid unavailable ({error}); keeping code blocks", file=sys.stderr)
        return None

    chrome = find_chrome()
    if not chrome:
        print("warning: no Chrome/Chromium binary found; keeping code blocks", file=sys.stderr)
        return None

    jobs = [{"source": source, "theme": theme} for source in sources for theme in ("default", "dark")]
    harness = CACHE_DIR / "harness.html"
    harness.write_text(
        HARNESS.replace("__PAYLOAD__", json.dumps(jobs).replace("</", "<\\/")), encoding="utf-8"
    )

    port = _serve(CACHE_DIR)
    command = [
        chrome, "--headless=new", "--disable-gpu", "--no-sandbox", "--hide-scrollbars",
        "--virtual-time-budget=30000", "--dump-dom", f"http://127.0.0.1:{port}/harness.html",
    ]
    try:
        completed = subprocess.run(command, capture_output=True, text=True, timeout=timeout, check=False)
    except subprocess.TimeoutExpired:
        print("warning: diagram rendering timed out; keeping code blocks", file=sys.stderr)
        return None

    match = re.search(r"<body[^>]*>(.*)</body>", completed.stdout, re.DOTALL)
    if not match:
        print("warning: diagram rendering produced no output; keeping code blocks", file=sys.stderr)
        return None

    parts = match.group(1).split(SPLIT)
    if len(parts) != len(jobs):
        print("warning: diagram rendering was incomplete; keeping code blocks", file=sys.stderr)
        return None

    for part in parts:
        if FAILED in part or not part.strip().startswith("<svg"):
            print("warning: a diagram failed to parse; rendering it as code", file=sys.stderr)
            return None

    return [(parts[i * 2], parts[i * 2 + 1]) for i in range(len(sources))]
