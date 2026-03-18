# Plan

Use this phase to turn a completed `spec.md` into design artifacts.

## Steps

1. Run `.specify/scripts/bash/setup-plan.sh --json`.
2. Load `spec.md`, copied `plan.md`, and `.specify/memory/constitution.md`.
3. Fill technical context and constitution checks.
4. Resolve planning unknowns in `research.md`.
5. Extract entities into `data-model.md`.
6. Define external interfaces in `contracts/` when applicable.
7. Create `quickstart.md`.
8. Run `.specify/scripts/bash/update-agent-context.sh codex`.
9. Re-check constitution compliance after design artifacts exist.

## Output

- Absolute paths to `plan.md`, `research.md`, `data-model.md`, `quickstart.md`
- Contract files generated under `contracts/`
- Branch or feature identifier
