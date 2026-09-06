#!/usr/bin/env bash
# ============================================================================
# fetch-designer-skills.sh
# ============================================================================
# Grabs Owl-Listener/designer-skills from GitHub and places them in
# .agents/designer-skills/ for use with OpenCode, Claude Code, or any
# AI agent that reads markdown context files.
#
# Usage:
#   chmod +x fetch-designer-skills.sh
#   ./fetch-designer-skills.sh
#
# The script is idempotent — safe to run multiple times.
# ============================================================================

set -euo pipefail

REPO_URL="https://github.com/Owl-Listener/designer-skills.git"
TEMP_DIR="$(mktemp -d)"
TARGET_DIR=".agents/designer-skills"

echo "📦 Fetching designer-skills..."
echo "   Repo: $REPO_URL"
echo "   Temp: $TEMP_DIR"
echo "   Target: $TARGET_DIR"
echo ""

# ── Clone ──────────────────────────────────────────────────────────────────
if ! git clone --depth 1 "$REPO_URL" "$TEMP_DIR/designer-skills" 2>/dev/null; then
    echo "❌ Failed to clone repository. Check your internet connection."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# ── Prepare target ─────────────────────────────────────────────────────────
mkdir -p "$TARGET_DIR"

# ── Copy skills ────────────────────────────────────────────────────────────
SKILLS_SOURCE="$TEMP_DIR/designer-skills/skills"

echo "🗂️  Copying skill categories..."

for category in ui-design interaction-design design-systems visual-critique research strategy design-ops; do
    if [ -d "$SKILLS_SOURCE/$category" ]; then
        cp -r "$SKILLS_SOURCE/$category" "$TARGET_DIR/"
        file_count=$(find "$TARGET_DIR/$category" -name '*.md' | wc -l)
        echo "   ✓ $category/ ($file_count skills)"
    else
        echo "   ⚠ $category/ not found in repo"
    fi
done

# ── Copy commands (if available) ───────────────────────────────────────────
if [ -d "$TEMP_DIR/designer-skills/commands" ]; then
    cp -r "$TEMP_DIR/designer-skills/commands" "$TARGET_DIR/"
    cmd_count=$(find "$TARGET_DIR/commands" -name '*.md' | wc -l)
    echo "   ✓ commands/ ($cmd_count commands)"
fi

# ── Create index ───────────────────────────────────────────────────────────
cat > "$TARGET_DIR/INDEX.md" << 'EOF'
# Designer Skills Index

> Auto-generated index of available design skills.
> Use `/add .agents/designer-skills/[category]/[skill].md` in OpenCode
> or reference these files in your prompts.

## Skill Categories

EOF

for category_dir in "$TARGET_DIR"/*/; do
    category=$(basename "$category_dir")
    [ "$category" = "INDEX.md" ] && continue
    [ "$category" = "commands" ] && continue

    echo "### ${category}" >> "$TARGET_DIR/INDEX.md"
    echo "" >> "$TARGET_DIR/INDEX.md"

    for skill_file in "$category_dir"*.md; do
        [ -f "$skill_file" ] || continue
        skill_name=$(basename "$skill_file" .md)
        # Extract first line as description
        description=$(head -n 1 "$skill_file" | sed 's/^#* *//')
        echo "- **${skill_name}** — ${description}" >> "$TARGET_DIR/INDEX.md"
    done
    echo "" >> "$TARGET_DIR/INDEX.md"
done

# ── Create usage guide ─────────────────────────────────────────────────────
cat > "$TARGET_DIR/USAGE.md" << 'EOF'
# Using Designer Skills with OpenCode

## Quick Start

```bash
# In your project directory, start OpenCode:
opencode

# Add a specific skill before your prompt:
> /add .agents/designer-skills/ui-design/color-palette.md
> /add docs/PRD.md

# Reference the skill in your prompt:
> "Execute the color palette workflow from the skill file.
>  Apply it to my app per PRD.md Section 7."
```

## Available Skills

Browse `INDEX.md` for the full list.

### Most Useful for Solo Developers

| Skill | File | When to Use |
|---|---|---|
| Color Palette | `ui-design/color-palette.md` | Before building — generate brand colors |
| Type System | `ui-design/type-system.md` | Before building — generate typography scale |
| Design Screen | `ui-design/design-screen.md` | During build — design a specific screen |
| Design Form | `interaction-design/design-form.md` | During build — design forms with validation |
| Map States | `interaction-design/map-states.md` | During build — model component states |
| Tokenize | `design-systems/tokenize.md` | After designing — extract tokens from design |
| Create Component | `design-systems/create-component.md` | During build — scaffold component specs |
| Critique Screen | `visual-critique/critique-screen.md` | After build — audit UI quality |

## Tips

- **Add the skill + your PRD together** — the skill provides the workflow, the PRD provides the context
- **Run one skill at a time** — don't overload context with multiple skills
- **Save the output** — the skill generates design decisions; save them to `design/` for reuse
- **Switch to Opus-tier model for design** — design reasoning needs your best model

## Example Session

```bash
opencode
> /model anthropic/claude-opus-4
> /add .agents/designer-skills/ui-design/color-palette.md
> /add docs/PRD.md
> "Run the color palette workflow for my coaching app.
>  Mood: professional, calm, trustworthy. Warm but not playful.
>  Output CSS custom properties."
# → Save output to design/color-palette.css

> /add .agents/designer-skills/ui-design/design-screen.md
> /add docs/WIREFRAMES.md
> "Design the dashboard screen per WIREFRAMES.md Screen 2.
>  Use the color palette from design/color-palette.css."
# → Save output to design/screen-dashboard.md
```
EOF

# ── Cleanup ────────────────────────────────────────────────────────────────
rm -rf "$TEMP_DIR"

# ── Summary ────────────────────────────────────────────────────────────────
echo ""
echo "✅ Designer skills fetched successfully!"
echo ""
echo "📁 Location: $TARGET_DIR/"
echo ""
echo "📋 Next steps:"
echo "   1. Review $TARGET_DIR/INDEX.md for available skills"
echo "   2. Read $TARGET_DIR/USAGE.md for OpenCode integration"
echo "   3. Start using skills: /add .agents/designer-skills/ui-design/color-palette.md"
echo ""
