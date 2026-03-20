# Finalize GitHub PR Principles

## Commit cleanup

- Review the final diff against the base branch before touching commit history.
- Compute the diff from the merge-base with the base branch so unrelated base-branch commits do not pollute the PR story.
- Keep the final history centered on semantic change, not iteration noise.
- Prefer 1 commit for one coherent feature.
- Prefer 2 commits when separating spec/docs/workflow context from implementation makes review easier.
- Use 3 commits only when that clearly improves reviewability.
- Create a backup branch before any reset or rebase.
- Preserve intended content unless the user explicitly asks to remove scope.
- Use `git push --force-with-lease`, not `--force`.

## PR narrative

- Describe the final user-visible behavior and architecture.
- Do not narrate the cleanup process in the PR body.
- Keep debug commits, lint fixes, and agent-process steps out of the reviewer story.
- Prefer a draft PR first.
- Explain validation with the actual commands run.
- Include rollback notes when the change adds migrations, runtime dependencies, or third-party integration risk.

## Operational notes from this session

- If sandboxed tests fail with permission errors such as `listen EPERM`, verify whether the issue is environmental before treating it as a product regression.
- If `gh pr create` is interrupted, check whether a PR was created before retrying.
- When rewriting history for a branch that already contains the right files, rebuilding from the base with `git reset --soft <base>` plus selective staging is often faster than interactive rebase.

## External reference note

The user also pointed to `https://x.com/trq212/article/2033949937936085378` as inspiration. That page required login at the time this skill was created, so its contents could not be verified directly. If the article text becomes available later, update this skill to incorporate any stronger heuristics about PR framing or commit slicing.
