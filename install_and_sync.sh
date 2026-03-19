#!/usr/bin/env bash
set -Eeuo pipefail

# install_and_sync.sh
#
# Install one or more skills from GitHub URLs into a shared skills root using
# the skill-installer helper, then sync all valid skills into Codex/Gemini and
# Claude skill directories via sync_global_skills.sh.

SCRIPT_DIR="$(
  cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
)"
SKILLS_ROOT="$SCRIPT_DIR"
WORKSPACE_MODE="auto"
FORCE=0
VERBOSE=0
METHOD="auto"
INSTALL_NAME=""
URLS=()

INSTALLER_SCRIPT="$SCRIPT_DIR/skill-installer/scripts/install-skill-from-github.py"
SYNC_SCRIPT="$SCRIPT_DIR/sync_global_skills.sh"

log()  { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
err()  { printf '[ERROR] %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options] <github-skill-url> [<github-skill-url> ...]

Options:
  --root PATH         Install into this skills root. Default: script directory
  --workspace MODE    auto | none | <path>. Default: auto
  --method MODE       auto | download | git. Default: auto
  --name NAME         Override the installed skill name (single URL only)
  --force             Pass --force through to sync_global_skills.sh
  --verbose           Print extra diagnostics
  -h, --help          Show this help

Examples:
  $(basename "$0") \
    https://github.com/obra/superpowers/tree/main/skills/finishing-a-development-branch

  $(basename "$0") --workspace none --method git \
    https://github.com/openai/skills/tree/main/skills/.experimental/some-skill

What this script does:
  1. Installs each GitHub skill URL into the selected skills root by calling:
       skill-installer/scripts/install-skill-from-github.py
  2. Runs sync_global_skills.sh against that same root.
  3. Leaves you with synced skills under:
       - ~/.agents/skills
       - ~/.claude/skills
       - optionally the selected workspace

Notes:
  - Public GitHub installs may require network access when you actually run this.
  - If a destination skill already exists, install is skipped and sync still runs.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      shift; [[ $# -gt 0 ]] || die "--root requires a value"; SKILLS_ROOT="$1" ;;
    --workspace)
      shift; [[ $# -gt 0 ]] || die "--workspace requires a value"; WORKSPACE_MODE="$1" ;;
    --method)
      shift; [[ $# -gt 0 ]] || die "--method requires a value"; METHOD="$1" ;;
    --name)
      shift; [[ $# -gt 0 ]] || die "--name requires a value"; INSTALL_NAME="$1" ;;
    --force)
      FORCE=1 ;;
    --verbose)
      VERBOSE=1 ;;
    -h|--help)
      usage
      exit 0 ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        URLS+=("$1")
        shift
      done
      break ;;
    -*)
      die "Unknown argument: $1" ;;
    *)
      URLS+=("$1") ;;
  esac
  shift
done

[[ "${#URLS[@]}" -gt 0 ]] || {
  usage
  die "Provide at least one GitHub skill URL."
}

if [[ -n "$INSTALL_NAME" && "${#URLS[@]}" -ne 1 ]]; then
  die "--name can only be used with a single GitHub skill URL."
fi

case "$METHOD" in
  auto|download|git) ;;
  *) die "--method must be one of: auto, download, git" ;;
esac

command -v python3 >/dev/null 2>&1 || die "python3 is required"
[[ -f "$INSTALLER_SCRIPT" ]] || die "Installer script not found: $INSTALLER_SCRIPT"
[[ -f "$SYNC_SCRIPT" ]] || die "Sync script not found: $SYNC_SCRIPT"

abspath() {
  python3 - "$1" <<'PY'
import os, sys
print(os.path.abspath(os.path.expanduser(sys.argv[1])))
PY
}

run_install() {
  local url="$1"
  local -a cmd=(
    python3
    "$INSTALLER_SCRIPT"
    --url "$url"
    --dest "$SKILLS_ROOT"
    --method "$METHOD"
  )

  if [[ -n "$INSTALL_NAME" ]]; then
    cmd+=(--name "$INSTALL_NAME")
  fi

  log "Installing skill from: $url"

  local output
  if output="$("${cmd[@]}" 2>&1)"; then
    [[ -n "$output" ]] && printf '%s\n' "$output"
    return 0
  fi

  if [[ "$output" == *"Destination already exists:"* ]]; then
    warn "$output"
    warn "Continuing with sync for the existing skill."
    return 0
  fi

  printf '%s\n' "$output" >&2
  return 1
}

SKILLS_ROOT="$(abspath "$SKILLS_ROOT")"
log "Skills root : $SKILLS_ROOT"
log "Workspace   : $WORKSPACE_MODE"
log "Method      : $METHOD"

for url in "${URLS[@]}"; do
  run_install "$url"
done

sync_cmd=(
  bash
  "$SYNC_SCRIPT"
  --root "$SKILLS_ROOT"
  --workspace "$WORKSPACE_MODE"
)

if [[ "$FORCE" -eq 1 ]]; then
  sync_cmd+=(--force)
fi

if [[ "$VERBOSE" -eq 1 ]]; then
  sync_cmd+=(--verbose)
fi

log "Syncing installed skills"
"${sync_cmd[@]}"

printf '\n[DONE] Installed and synced %s URL(s)\n' "${#URLS[@]}"
printf '[DONE] Restart Codex to pick up new skills.\n'
