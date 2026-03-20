#!/usr/bin/env python3
"""Generate a reviewer-oriented PR body draft from local git metadata."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from pathlib import PurePosixPath


def run_git(args: list[str], cwd: Path) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=cwd,
        check=True,
        text=True,
        capture_output=True,
    )
    return result.stdout.strip()


def current_branch(cwd: Path) -> str:
    return run_git(["branch", "--show-current"], cwd)


def merge_base(base: str, branch: str, cwd: Path) -> str:
    return run_git(["merge-base", base, branch], cwd)


def commit_list(base: str, branch: str, cwd: Path) -> list[str]:
    output = run_git(["log", "--oneline", f"{base}..{branch}"], cwd)
    return [line for line in output.splitlines() if line.strip()]


def changed_files(compare_base: str, branch: str, cwd: Path) -> list[str]:
    output = run_git(["diff", "--name-only", compare_base, branch], cwd)
    return [line for line in output.splitlines() if line.strip()]


def diff_stat(compare_base: str, branch: str, cwd: Path) -> str:
    return run_git(["diff", "--stat", compare_base, branch], cwd)


DOC_NAMES = {
    "agents.md",
    "readme",
    "readme.md",
    "changelog",
    "changelog.md",
    "contributing",
    "contributing.md",
    "license",
    "license.md",
}

TOOLING_NAMES = {
    "makefile",
    "justfile",
    "dockerfile",
    "docker-compose.yml",
    "docker-compose.yaml",
    "package.json",
    "package-lock.json",
    "pnpm-lock.yaml",
    "yarn.lock",
    "pyproject.toml",
    "requirements.txt",
    "go.mod",
    "go.sum",
    "cargo.toml",
    "cargo.lock",
    "composer.json",
    "composer.lock",
    "gemfile",
    "gemfile.lock",
}

APP_ROOTS = (
    "src/",
    "app/",
    "apps/",
    "cmd/",
    "internal/",
    "pkg/",
    "lib/",
    "server/",
    "client/",
    "frontend/",
    "backend/",
    "web/",
    "api/",
)

TEST_ROOTS = (
    "tests/",
    "test/",
    "__tests__/",
    "__mocks__/",
    "spec/",
)

INFRA_ROOTS = (
    ".github/",
    ".gitlab/",
    ".circleci/",
    "infra/",
    "infrastructure/",
    "terraform/",
    "helm/",
    "charts/",
    "k8s/",
    "deploy/",
    "deployment/",
)

TOOLING_ROOTS = (
    "scripts/",
    ".husky/",
    ".vscode/",
    ".devcontainer/",
    "tools/",
    "bin/",
)


def has_suffix(path: PurePosixPath, suffixes: tuple[str, ...]) -> bool:
    joined = "".join(path.suffixes).lower()
    return any(joined.endswith(suffix) for suffix in suffixes)


def is_doc_path(path: str) -> bool:
    posix_path = PurePosixPath(path)
    name = posix_path.name.lower()
    if (
        path.startswith(("docs/", "doc/", "specs/", "issuelog/", ".specify/", ".codex/", "references/"))
        or name in DOC_NAMES
    ):
        return True
    return has_suffix(posix_path, (".md", ".rst", ".adoc"))


def is_test_path(path: str) -> bool:
    posix_path = PurePosixPath(path)
    name = posix_path.name.lower()
    if path.startswith(TEST_ROOTS):
        return True
    return (
        name.startswith("test_")
        or name.endswith("_test.py")
        or name.endswith("_test.go")
        or ".test." in name
        or ".spec." in name
    )


def is_infra_path(path: str) -> bool:
    posix_path = PurePosixPath(path)
    name = posix_path.name.lower()
    if path.startswith(INFRA_ROOTS):
        return True
    return name.endswith((".tf", ".tfvars")) or name.startswith("dockerfile")


def is_tooling_path(path: str) -> bool:
    posix_path = PurePosixPath(path)
    name = posix_path.name.lower()
    if path.startswith(TOOLING_ROOTS) or name in TOOLING_NAMES:
        return True
    return has_suffix(
        posix_path,
        (
            ".yml",
            ".yaml",
            ".json",
            ".toml",
            ".ini",
            ".cfg",
            ".conf",
        ),
    )


def is_app_path(path: str) -> bool:
    posix_path = PurePosixPath(path)
    name = posix_path.name.lower()
    if path.startswith(APP_ROOTS):
        return True
    return has_suffix(
        posix_path,
        (
            ".py",
            ".ts",
            ".tsx",
            ".js",
            ".jsx",
            ".go",
            ".rs",
            ".java",
            ".kt",
            ".rb",
            ".php",
            ".swift",
            ".c",
            ".cc",
            ".cpp",
            ".h",
            ".hpp",
        ),
    ) and not name.endswith(".d.ts")


def bucket_files(paths: list[str]) -> dict[str, list[str]]:
    buckets = {
        "docs": [],
        "application": [],
        "tests": [],
        "tooling": [],
        "infra": [],
        "other": [],
    }
    for path in paths:
        if is_doc_path(path):
            buckets["docs"].append(path)
        elif is_test_path(path):
            buckets["tests"].append(path)
        elif is_infra_path(path):
            buckets["infra"].append(path)
        elif is_tooling_path(path):
            buckets["tooling"].append(path)
        elif is_app_path(path):
            buckets["application"].append(path)
        else:
            buckets["other"].append(path)
    return buckets


def flat_bullets(values: list[str]) -> str:
    if not values:
        return "- TODO\n"
    return "".join(f"- {value}\n" for value in values)


def limited_paths(values: list[str], limit: int = 6) -> list[str]:
    if len(values) <= limit:
        return values
    return [*values[:limit], f"... and {len(values) - limit} more"]


def build_implementation_summary(buckets: dict[str, list[str]]) -> list[str]:
    items: list[str] = []
    if buckets["docs"]:
        items.append(
            "Added or updated documentation, specs, or workflow notes "
            f"({', '.join(limited_paths(buckets['docs']))})"
        )
    if buckets["application"]:
        items.append(
            "Implemented product or library code changes "
            f"({', '.join(limited_paths(buckets['application']))})"
        )
    if buckets["tests"]:
        items.append(
            "Added or updated automated coverage "
            f"({', '.join(limited_paths(buckets['tests']))})"
        )
    if buckets["tooling"]:
        items.append(
            "Updated repo tooling and local developer workflow "
            f"({', '.join(limited_paths(buckets['tooling']))})"
        )
    if buckets["infra"]:
        items.append(
            "Adjusted CI, deployment, or infrastructure-related files "
            f"({', '.join(limited_paths(buckets['infra']))})"
        )
    if buckets["other"]:
        items.append(f"Additional touched paths: {', '.join(limited_paths(buckets['other']))}")
    return items


def build_review_order(buckets: dict[str, list[str]]) -> list[str]:
    order: list[str] = []
    if buckets["docs"]:
        order.append("Read the docs/spec/workflow changes first to understand scope and intended behavior.")
    if buckets["application"]:
        order.append("Review the product or library code changes next.")
    if buckets["infra"]:
        order.append("Review CI, deployment, or infrastructure-related changes after the core code.")
    if buckets["tooling"]:
        order.append("Review tooling or workflow changes once the main behavior is clear.")
    if buckets["tests"]:
        order.append("Review automated coverage last to confirm the intended behavior is exercised.")
    if not order:
        order.append("Review the final diff directly; this branch has no recognized category buckets.")
    return order


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", default=".", help="Repository path. Defaults to current directory.")
    parser.add_argument("--base", default="main", help="Base branch to compare against.")
    parser.add_argument("--branch", help="Branch to describe. Defaults to current branch.")
    parser.add_argument("--problem", action="append", default=[], help="Problem statement bullet.")
    parser.add_argument("--scope", action="append", default=[], help="Scope bullet.")
    parser.add_argument(
        "--validation-command",
        action="append",
        default=[],
        help="Validation command that was run.",
    )
    parser.add_argument(
        "--validation-note",
        action="append",
        default=[],
        help="Validation note or caveat.",
    )
    parser.add_argument("--non-goal", action="append", default=[], help="Non-goal bullet.")
    parser.add_argument("--risk", action="append", default=[], help="Risk bullet.")
    parser.add_argument("--output", help="Write markdown to this file instead of stdout.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo = Path(args.repo).resolve()
    branch = args.branch or current_branch(repo)
    compare_base = merge_base(args.base, branch, repo)

    commits = commit_list(args.base, branch, repo)
    files = changed_files(compare_base, branch, repo)
    stat = diff_stat(compare_base, branch, repo)
    buckets = bucket_files(files)
    implementation_summary = build_implementation_summary(buckets)
    review_order = build_review_order(buckets)
    default_scope = [
        f"Changes compared from merge-base `{compare_base}` between `{args.base}` and `{branch}`.",
        f"{len(commits)} commit(s) and {len(files)} changed file(s) are included in the final diff.",
    ]

    body = f"""## Problem

{flat_bullets(args.problem or [f"This branch introduces reviewable changes on top of `{args.base}` and should be described in terms of final behavior, not iteration history."])}
## Scope

{flat_bullets(args.scope or default_scope)}
## Implementation Summary

{flat_bullets(implementation_summary)}
## Non-goals

{flat_bullets(args.non_goal or ['TODO: add explicit non-goals for this PR.'])}
## Validation

Commands run:

{flat_bullets([f'`{command}`' for command in args.validation_command] or ['TODO: add the validation commands you actually ran.'])}
Notes:

{flat_bullets(args.validation_note or ['TODO: add environment notes, warnings, or skipped checks if relevant.'])}
## Risks and Rollback Notes

{flat_bullets(args.risk or ['TODO: add rollback notes and any runtime, migration, or third-party integration risks.'])}
## Review Order

{flat_bullets(review_order)}
## Appendix

- Base branch: `{args.base}`
- Merge base: `{compare_base}`
- Feature branch: `{branch}`
- Final commit count in diff: `{len(commits)}`
- Final changed file count in diff: `{len(files)}`

### Commit List

{flat_bullets(commits or ['No commits found in the requested diff.'])}
### Diff Stat

```text
{stat}
```
"""

    if args.output:
        Path(args.output).write_text(body)
    else:
        sys.stdout.write(body)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
