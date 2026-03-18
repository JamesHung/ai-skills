# Implement

Use this phase when `tasks.md` is ready and the user wants code changes executed.

## Steps

1. Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks`.
2. Check any `checklists/*.md` status before coding.
3. Load `tasks.md`, `plan.md`, and supporting artifacts.
4. Execute work phase by phase, respecting dependencies and `[P]` markers.
5. Update `tasks.md` as tasks complete.
6. Run relevant tests and validations required by the plan and constitution.

## Output

- Completed task IDs
- Files changed
- Tests run and results
- Remaining blockers or follow-up work
