# Clarify

Use this phase after `spec.md` exists and before planning.

## Steps

1. Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only`.
2. Load the current `spec.md`.
3. Scan for high-impact ambiguity in scope, actors, data model, UX flow, quality attributes, dependencies, edge cases, and acceptance criteria.
4. Ask exactly one question at a time, up to 5 total.
5. Prefer multiple choice with a recommended option when practical.
6. After each accepted answer, update `spec.md` immediately and append a bullet in `## Clarifications`.
7. Keep updates minimal, testable, and non-contradictory.

## Output

- Number of questions asked
- Absolute path to updated `spec.md`
- Sections touched
- Outstanding vs deferred ambiguities
- Recommendation to proceed or clarify further
