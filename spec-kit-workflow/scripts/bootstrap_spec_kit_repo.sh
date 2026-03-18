#!/usr/bin/env bash

set -euo pipefail

root="$(pwd)"

if ~/.codex/skills/spec-kit-workflow/scripts/check_spec_kit_repo.sh --json | grep -q '"ready":true'; then
  echo "spec-kit is already enabled in $root"
  exit 0
fi

if command -v specify >/dev/null 2>&1; then
  specify init . --ai codex --force --ignore-agent-tools
else
  if ! command -v uvx >/dev/null 2>&1; then
    echo "Neither specify nor uvx is available; cannot bootstrap spec-kit." >&2
    exit 1
  fi

  uvx --from git+https://github.com/github/spec-kit.git specify init . --ai codex --force --ignore-agent-tools
fi

mkdir -p "$root/specs"

echo "spec-kit bootstrap completed in $root"
