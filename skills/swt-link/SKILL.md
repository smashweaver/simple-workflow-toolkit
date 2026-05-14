---
name: "swt:link"
inherits: "swt:think"
description: >
  Universal skill installer/linker for SWT. Supports both symlinking (Developer Mode) 
  and physical copying (Stable Mode) of skills into .agents/ and .claude/ discovery paths.
user-invocable: true
allowed-tools:
  - Bash
---

# /swt:link & /swt:install — Universal Skill Management

These skills automate the installation of SWT skills into multiple AI agent discovery paths. 

## Commands

### 1. /swt:flow install (Physical Copy)
Use this for **Stable Mode**. It copies all skills physically into the discovery paths. This is recommended for general use to prevent "bleeding edge" development changes from affecting your environment.
> *"install my skills"* or *"/swt:flow install"*

### 2. /swt:flow link (Symlink)
Use this for **Developer Mode (Dogfooding)**. It symlinks the skills, meaning any change to the source code is immediately live.
> *"link my skills"* or *"/swt:flow link"*

### 3. Global Scope
Add `--global` to target your home directory (`~/.agents`, etc.).
> *"/swt:flow install --global"* or *"/swt:flow link --global"*

---

## Technical Details

The skill executes the `scripts/link.sh` utility located within the skill directory.

### Discovery Paths Targeted:
- `.agents/skills`
- `.claude/skills`

> **Note**: `CLAUDE.md` is natively discovered by Claude Code at the project root and does NOT need symlinking. Use `/swt:init --claude` to generate it.

### Flags supported via prompt:
- `--clear`: Remove existing SWT links before refreshing.
- `--global`: Target home directory paths.
- `--dry-run`: Show what would be linked without executing.

---

## Execution

The agent will:
1. Locate `SWT_HOME` (from environment or project root).
2. Execute the appropriate script:
   - **Stable**: `scripts/install.sh [flags] [path]`
   - **Dev**: `scripts/link.sh [flags] [path]`
3. Confirm the installation paths to the user.
