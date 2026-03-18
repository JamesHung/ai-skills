#!/usr/bin/env bash

set -euo pipefail

json=false
if [[ "${1:-}" == "--json" ]]; then
  json=true
fi

root="$(pwd)"
has_specify=false
has_specs=false
has_scripts=false
has_templates=false
has_constitution=false

[[ -d "$root/.specify" ]] && has_specify=true
[[ -d "$root/specs" ]] && has_specs=true
[[ -x "$root/.specify/scripts/bash/check-prerequisites.sh" ]] && has_scripts=true
[[ -f "$root/.specify/templates/spec-template.md" ]] && has_templates=true
[[ -f "$root/.specify/memory/constitution.md" ]] && has_constitution=true

ready=false
if [[ "$has_specify" == true && "$has_scripts" == true && "$has_templates" == true && "$has_constitution" == true ]]; then
  ready=true
fi

if [[ "$json" == true ]]; then
  printf '{"root":"%s","has_specify":%s,"has_specs":%s,"has_scripts":%s,"has_templates":%s,"has_constitution":%s,"ready":%s}\n' \
    "$root" "$has_specify" "$has_specs" "$has_scripts" "$has_templates" "$has_constitution" "$ready"
else
  echo "root: $root"
  echo "has_specify: $has_specify"
  echo "has_specs: $has_specs"
  echo "has_scripts: $has_scripts"
  echo "has_templates: $has_templates"
  echo "has_constitution: $has_constitution"
  echo "ready: $ready"
fi
