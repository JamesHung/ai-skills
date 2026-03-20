#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(
  cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCS_DIR="$REPO_ROOT/docs"

if [[ ! -d "$DOCS_DIR" ]]; then
  printf '[INFO] docs/ not found; nothing to check.\n'
  exit 0
fi

if ! find "$DOCS_DIR" -type f -name '*.md' -print -quit | grep -q .; then
  printf '[INFO] No Markdown files under docs/; nothing to check.\n'
  exit 0
fi

if matches="$(
  rg -n --pcre2 '(?<!!)\[[^][]+\]\((?!https?://|mailto:|#|/)' "$DOCS_DIR" --glob '*.md'
)"; then
  printf '[ERROR] Found inline relative Markdown links in docs/. Use reference-style links instead.\n'
  printf '%s\n' "$matches"
  exit 1
fi

printf '[INFO] docs/ Markdown reference-style link check passed.\n'
