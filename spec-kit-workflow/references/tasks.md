# Tasks

Use this phase when `plan.md` exists and you need an executable task list.

## Steps

1. Run `.specify/scripts/bash/check-prerequisites.sh --json`.
2. Load `plan.md` and `spec.md`.
3. Load optional artifacts: `data-model.md`, `research.md`, `contracts/`, `quickstart.md`.
4. Generate `tasks.md` organized by user story and dependency order.
5. Keep the exact task format:

```text
- [ ] T001 [P] [US1] Description with file path
```

6. Only create test tasks when requested by the spec or user.
7. Include setup, foundations, story phases, and final polish.

## Output

- Absolute path to `tasks.md`
- Total task count
- Count per user story
- Parallelizable work
- Suggested MVP scope
