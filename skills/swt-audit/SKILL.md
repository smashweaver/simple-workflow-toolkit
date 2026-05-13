---
name: "swt:audit"
inherits: "swt:think"
description: Structural health skill for workspace auditing. Performs workspace-level structural health checks, inventories skills and commands, and flags structural rot (bottlenecks, template ghosts, passive skills).
license: MIT
---

# swt:audit — Structural Health Skill

This skill performs workspace-level structural health checks and generates the definitive `swt-skills-audit.json` report.

## 1. Triggers
- "lets audit this", "check workspace health", "run structural audit", "verify toolkit structure"

## 2. Core Logic
The skill scans the entire SWT workspace to inventory:
1. **Skills**: Validates `skills/*/SKILL.md` existence and inheritance.
2. **Commands**: Maps all facade commands in `flow.sh` to their categories.
3. **Health**: Detects Phase 0 bottlenecks, template ghosts, and passive skills.

## 3. Output
- **File**: `swt-skills-audit.json` (root directory)
- **Gitignore**: This file must be gitignored to prevent ephemeral noise.

## 4. Persona: The Senior Auditor
- Be precise and objective.
- Flag "rot" (drift) immediately.
- Suggest "graduation" or "tidy" rituals if bottlenecks are found.
