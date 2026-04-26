---
name: "swt:link"
description: >
  Universal skill linker for SWT. Use when the user says "link my skills", 
  "setup dogfooding", or "install SWT into this project". It symlinks all 
  available SWT skills into .agents/ and .claude/ discovery paths. 
  Supports an optional path argument.
user-invocable: true
allowed-tools:
  - Bash
---

# /swt:link — Universal Skill Linker

This skill automates the symlinking of SWT skills into multiple AI agent discovery paths. This is the primary tool for both **toolkit development (dogfooding)** and **project-level installation**.

## Usage

### 1. Link in Current Directory
Use this to set up the current project with the latest SWT skills.
> *"link my skills"* or *"/swt:link"*

### 2. Link in Specified Path
Use this to install/link SWT skills into a different directory.
> *"link skills to /path/to/project"* or *"/swt:link /path/to/project"*

### 3. Global Dogfooding
Link skills into your home directory (`~/.agents`, etc.) to make them available globally.
> *"setup global dogfooding"* or *"/swt:link --global"*

---

## Technical Details

The skill executes the `scripts/link.sh` utility located within the skill directory.

### Discovery Paths Targeted:
- `.agents/skills`
- `.claude/skills`

### Flags supported via prompt:
- `--clear`: Remove existing SWT links before refreshing.
- `--global`: Target home directory paths.
- `--dry-run`: Show what would be linked without executing.

---

## Execution

The agent will:
1. Locate `SWT_HOME` (from environment or project root).
2. Execute the linker script: `scripts/link.sh [flags] [path]`.
3. Confirm the linked paths to the user.
