---
name: spec-kit-workflow
description: Run spec-driven development workflows in repositories that use `spec-kit`/`specify` conventions such as `.specify/`, `specs/`, and feature documents. Use when the user wants to create a spec, clarify requirements, generate a plan, derive tasks, implement from `tasks.md`, or migrate deprecated `/speckit.*` prompt usage to Codex global skills.
---

# Spec Kit Workflow

Use this skill instead of deprecated custom prompts like `/speckit.specify` or `/prompts:speckit.plan`.

First verify the repository is wired for spec-kit. Run:

```bash
~/.codex/skills/spec-kit-workflow/scripts/check_spec_kit_repo.sh --json
```

If the repo is not ready, bootstrap it first from repository root:

```bash
~/.codex/skills/spec-kit-workflow/scripts/bootstrap_spec_kit_repo.sh
```

Re-run the readiness check after bootstrap and only stop if it still fails.

## Core Rules

- Work from repository root.
- If `.specify/` is missing, install spec-kit before running any phase-specific workflow.
- Prefer the repo's own scripts in `.specify/scripts/bash/` over recreating logic manually.
- Keep artifacts under `specs/<NNN-feature-name>/`.
- Use absolute paths when reporting generated files.
- If the repository still relies on deprecated prompt files, treat them as reference material only; do not depend on slash commands.
- Preserve any existing `AGENTS.md`, `CLAUDE.md`, or other agent files unless the workflow explicitly updates them.
- Prefer a locally installed `specify` binary; fall back to `uvx --from git+https://github.com/github/spec-kit.git specify ...` when `specify` is unavailable.

## Workflow

### 1. Specify

- Read [specify.md](references/specify.md).
- Generate a short feature name.
- Check highest feature number across branches and `specs/`.
- Run `.specify/scripts/bash/create-new-feature.sh --json --number <N> --short-name "<name>" "<feature description>"` exactly once.
- Fill `spec.md` from the repo template.
- Create or update `checklists/requirements.md`.

### 2. Clarify

- Read [clarify.md](references/clarify.md).
- Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only`.
- Ask at most 5 high-impact questions, one at a time.
- Write accepted answers back into `spec.md` incrementally and keep a `## Clarifications` section.

### 3. Plan

- Read [plan.md](references/plan.md).
- Run `.specify/scripts/bash/setup-plan.sh --json`.
- Load `spec.md`, `.specify/memory/constitution.md`, and the copied `plan.md` template.
- Generate `research.md`, `data-model.md`, `contracts/`, and `quickstart.md`.
- Run `.specify/scripts/bash/update-agent-context.sh codex`.

### 4. Tasks

- Read [tasks.md](references/tasks.md).
- Run `.specify/scripts/bash/check-prerequisites.sh --json`.
- Build `tasks.md` by user story, keeping the strict checkbox format.
- Include only test tasks that the spec or user actually requires.

### 5. Implement

- Read [implement.md](references/implement.md).
- Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks`.
- Verify checklist status before implementation.
- Execute tasks phase by phase and mark completed items `[X]` in `tasks.md`.

## Trigger Phrases

- "use spec-kit"
- "run the spec workflow"
- "create a spec / plan / tasks from this repo"
- "migrate `/speckit.*` to skills"
- "implement from `tasks.md`"

## Resources

- `scripts/check_spec_kit_repo.sh`: fast repository readiness check.
- `scripts/bootstrap_spec_kit_repo.sh`: enables spec-kit in the current repository when missing.
- `references/specify.md`: feature specification workflow.
- `references/clarify.md`: clarification workflow.
- `references/plan.md`: implementation planning workflow.
- `references/tasks.md`: task generation workflow.
- `references/implement.md`: execution workflow.

Load only the reference file for the phase you are executing.
