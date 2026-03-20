---
name: finalize-gh-pr
description: "Clean up a local implementation branch into a reviewable GitHub pull request. Use when Codex needs to inspect a branch against its base, collapse noisy iterative commits into 1-3 semantic commits, preserve intended content while rewriting history, run repo-required validation, safely force-push with --force-with-lease, and create or update a reviewer-oriented draft PR with a strong title and body."
---

# Finalize GitHub PR

Turn a messy implementation branch into a clean, reviewable draft PR.

Use this skill when the user asks to clean up commit history, prepare a branch for review, force-push a rewritten branch, or generate a reviewer-oriented PR from the branch's final behavior instead of its iteration history.

## Workflow

### 1. Inspect the branch before changing history

Run these first:

- `git status --short`
- `git branch --show-current`
- `git branch --all --no-color`
- `BASE_COMMIT=$(git merge-base HEAD <base-branch>)`
- `git log --oneline --decorate --graph <base-branch>..HEAD`
- `git diff --stat "$BASE_COMMIT"..HEAD`
- `git diff --name-only "$BASE_COMMIT"..HEAD`

Decide whether the branch should stay as-is, collapse into 1 commit, collapse into 2 semantic commits, or split before review.

Center the PR story on final behavior and architecture, not the cleanup journey.

### 2. Choose the cleanup shape

Default shapes:

- `1 commit`: one coherent feature
- `2 commits`: spec/docs/workflow context plus implementation
- `3 commits`: only when it clearly improves reviewability

Keep intended content unless the user explicitly asks to remove scope.

### 3. Back up before rewriting

Before any reset or rebase:

- create a backup branch from current HEAD
- use a predictable name such as `backup-<branch>-before-cleanup`

### 4. Rewrite into semantic commits

When rebuilding from the base branch, this pattern is usually sufficient:

1. `git reset --soft <base-branch>`
2. `git reset`
3. stage the first semantic slice
4. run required checks for that slice when needed
5. commit with a clear message
6. stage the remaining slice
7. rerun required checks
8. commit with a clear message

Prefer commit messages such as:

- `docs(spec): ...`
- `feat: ...`
- `fix: ...`
- `test: ...`

### 5. Run repo-required validation

Use the repo's existing workflow. Check entrypoints first, such as `Makefile`, `package.json`, `pyproject.toml`, `go.mod`, or `Cargo.toml`.

If the repo exposes `lint`, `test`, and `build`, default to that order.

If Markdown changed and the repo requires a doc-link checker, run it before the final commit.

### 6. Push and create or update the PR

Before PR creation:

- verify the branch name
- check for an existing PR with `gh pr list --head <branch> --state all`

If history changed, push with:

- `git push --force-with-lease -u origin <branch>`

Prefer a draft PR unless the user explicitly asks for ready-for-review.

Write the PR body to a temp file and pass it via `gh pr create --body-file ...` or `gh pr edit --body-file ...`.

If you need a starter draft, run:

- `scripts/generate_pr_body.py --base <base-branch> --validation-command "<cmd>" --validation-note "<note>" --output /tmp/pr-body.md`

Treat the generated markdown as a draft. The script computes the merge-base automatically, but you still need to tighten the `Problem`, `Non-goals`, and `Risks and Rollback Notes` sections before opening the PR.

Use these sections in most PRs:

- `Problem`
- `Scope`
- `Implementation Summary`
- `Non-goals`
- `Validation`
- `Risks and Rollback Notes`
- `Review Order`

## Gotchas

- Do not rewrite history without creating a backup branch first.
- Do not use `git push --force` when `--force-with-lease` is sufficient.
- Do not let debug commits, lint-fix commits, or agent-process commits dominate the PR narrative.
- Do not assume an interrupted `gh pr create` failed; check whether a PR already exists first.
- Do not treat sandbox-only failures such as `listen EPERM` as product regressions until you verify the environment effect.
- Do not over-specify the commit shape. Use 1, 2, or 3 commits based on reviewability, not ideology.
- Do not paste the script output into GitHub without editing the placeholder bullets. The script is a scaffold, not the final review narrative.

## References

- Read [principles.md](references/principles.md) for the compact checklist.
- Read [article-notes.md](references/article-notes.md) for the distilled guidance adapted from the Anduril translation of Thariq Shihipar's article.

## Scripts

- `scripts/generate_pr_body.py`: generates a reviewer-oriented PR body draft from the current git diff, commit list, and validation metadata you provide.
