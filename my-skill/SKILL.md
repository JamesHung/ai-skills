---
name: my-skill
description: Validate that this shared skill is installed and can be explicitly invoked from Codex, Claude Code, or Gemini CLI.
---

# my-skill

## Goal
Confirm this shared skill repo is discoverable from multiple agent tools.

## Steps
1. Confirm this skill was loaded from a symlinked location.
2. Run `scripts/hello.sh` if shell execution is available.
3. Report the current working directory and the resolved skill path.
4. If the tool supports skill listing, mention that this skill was discovered successfully.

## Expected output
- Tool name
- Current working directory
- Resolved skill path
- Result of scripts/hello.sh
