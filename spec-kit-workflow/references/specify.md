# Specify

Use this phase when the user gives a new feature idea in natural language.

## Steps

1. Generate a concise short name.
2. Check existing feature numbers across git branches and `specs/`.
3. Run `.specify/scripts/bash/create-new-feature.sh --json --number <N> --short-name "<name>" "<description>"` exactly once.
4. Read `.specify/templates/spec-template.md`.
5. Write `spec.md` focused on user value and measurable outcomes, not implementation details.
6. Create or update `checklists/requirements.md`.
7. Validate the spec and resolve or surface at most 3 critical `[NEEDS CLARIFICATION]` markers.

## Output

- Branch name
- Absolute path to `spec.md`
- Absolute path to `checklists/requirements.md`
- Readiness for clarify or plan
