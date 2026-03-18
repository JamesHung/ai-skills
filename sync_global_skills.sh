#!/usr/bin/env bash
set -Eeuo pipefail

# sync_global_skills.sh
#
# Sync all skills under a root folder (default: $HOME/skills) into:
#   - $HOME/.agents/skills       (Codex + Gemini shared path)
#   - $HOME/.claude/skills       (Claude Code path)
#   - optionally: <workspace>/.agents/skills and <workspace>/.claude/skills
#
# A valid skill is any immediate child directory under SKILLS_ROOT that contains SKILL.md.
# Optionally initialize a missing skill via --init <name>.

SKILLS_ROOT="${HOME}/skills"
WORKSPACE_MODE="auto"   # auto | none | /path/to/workspace
FORCE=0
INIT_SKILL=""
VERBOSE=0

log()  { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
err()  { printf '[ERROR] %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Options:
  --root PATH         Skills root folder. Default: \$HOME/skills
  --workspace MODE    auto | none | <path>. Default: auto
  --init NAME         Initialize \$ROOT/NAME if missing, then sync all skills
  --force             Replace conflicting links/directories
  --verbose           Print extra diagnostics
  -h, --help          Show this help

What this script does:
  1. Scans immediate subfolders under the skills root.
  2. Treats folders containing SKILL.md as valid skills.
  3. Creates symlinks for every skill into:
       - \$HOME/.agents/skills/<name>
       - \$HOME/.claude/skills/<name>
       - <workspace>/.agents/skills/<name>   (optional)
       - <workspace>/.claude/skills/<name>   (optional)
  4. Runs structural smoke tests for every linked skill.
  5. If Gemini CLI is installed, runs: gemini skills list

Notes:
  - Codex and Gemini can both use .agents/skills.
  - Claude Code uses .claude/skills.
  - This script syncs ALL valid skill folders under the root, not just one.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      shift; [[ $# -gt 0 ]] || die "--root requires a value"; SKILLS_ROOT="$1" ;;
    --workspace)
      shift; [[ $# -gt 0 ]] || die "--workspace requires a value"; WORKSPACE_MODE="$1" ;;
    --init)
      shift; [[ $# -gt 0 ]] || die "--init requires a value"; INIT_SKILL="$1" ;;
    --force)
      FORCE=1 ;;
    --verbose)
      VERBOSE=1 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      die "Unknown argument: $1" ;;
  esac
  shift
done

validate_skill_name() {
  local name="$1"
  [[ "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "Skill name must match ^[a-z0-9][a-z0-9-]*$ ; got: $name"
}

abspath() {
  python3 - "$1" <<'PY'
import os, sys
print(os.path.abspath(os.path.expanduser(sys.argv[1])))
PY
}

resolve_path() {
  python3 - "$1" <<'PY'
import os, sys
print(os.path.realpath(os.path.expanduser(sys.argv[1])))
PY
}

ensure_dir() {
  mkdir -p "$1"
}

safe_write_if_missing() {
  local path="$1"
  shift
  if [[ -e "$path" ]]; then
    log "Exists, keep as-is: $path"
  else
    cat > "$path"
    log "Created: $path"
  fi
}

create_or_update_link() {
  local source="$1"
  local dest="$2"

  ensure_dir "$(dirname "$dest")"

  if [[ -L "$dest" ]]; then
    local current_target desired_target
    current_target="$(resolve_path "$dest")"
    desired_target="$(resolve_path "$source")"
    if [[ "$current_target" == "$desired_target" ]]; then
      [[ "$VERBOSE" -eq 1 ]] && log "Link already correct: $dest -> $current_target"
      return 0
    fi
    if [[ "$FORCE" -eq 1 ]]; then
      rm -f "$dest"
      ln -s "$source" "$dest"
      log "Replaced link: $dest -> $source"
      return 0
    fi
    warn "Conflicting symlink exists, skipped: $dest -> $current_target"
    return 1
  fi

  if [[ -e "$dest" ]]; then
    if [[ "$FORCE" -eq 1 ]]; then
      rm -rf "$dest"
      ln -s "$source" "$dest"
      log "Replaced existing path with symlink: $dest -> $source"
      return 0
    fi
    warn "Existing non-link path found, skipped: $dest"
    return 1
  fi

  ln -s "$source" "$dest"
  log "Linked: $dest -> $source"
}

init_skill_if_requested() {
  [[ -n "$INIT_SKILL" ]] || return 0
  validate_skill_name "$INIT_SKILL"

  local repo="$SKILLS_ROOT/$INIT_SKILL"
  ensure_dir "$repo/scripts"
  ensure_dir "$repo/references"

  safe_write_if_missing "$repo/SKILL.md" <<EOF_SKILL
---
name: ${INIT_SKILL}
description: Shared skill synced from the global skills root.
---

# ${INIT_SKILL}

## Goal
Confirm this shared skill is discoverable from Codex, Gemini CLI, and Claude Code.

## Steps
1. Report the current working directory.
2. Report the resolved skill path.
3. Run \`scripts/hello.sh\` if shell execution is available.
EOF_SKILL

  safe_write_if_missing "$repo/scripts/hello.sh" <<'EOF_HELLO'
#!/usr/bin/env bash
set -euo pipefail
echo "hello from shared skill: $(cd "$(dirname "$0")/.." && pwd)"
EOF_HELLO
  chmod +x "$repo/scripts/hello.sh"

  safe_write_if_missing "$repo/references/README.md" <<EOF_REF
# ${INIT_SKILL}

Optional supporting material for this skill.
EOF_REF
}

resolve_workspace() {
  case "$WORKSPACE_MODE" in
    auto)
      if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
      else
        pwd
      fi
      ;;
    none)
      printf ''
      ;;
    *)
      abspath "$WORKSPACE_MODE"
      ;;
  esac
}

list_valid_skills() {
  local root="$1"
  [[ -d "$root" ]] || return 0
  find "$root" -mindepth 1 -maxdepth 1 -type d | sort | while IFS= read -r dir; do
    if [[ -f "$dir/SKILL.md" ]]; then
      basename "$dir"
    else
      warn "Skipping folder without SKILL.md: $dir"
    fi
  done
}

run_structural_smoke_tests() {
  local skills_root="$1"
  local workspace_dir="$2"
  local count=0
  local fail=0

  printf '\n[SMOKE] Structural checks\n'
  while IFS= read -r skill_name; do
    [[ -n "$skill_name" ]] || continue
    count=$((count+1))

    local repo="$skills_root/$skill_name"
    local expected="$(resolve_path "$repo")"
    local user_agents="$HOME/.agents/skills/$skill_name"
    local user_claude="$HOME/.claude/skills/$skill_name"

    [[ -f "$repo/SKILL.md" ]] || { warn "Missing SKILL.md: $repo"; fail=1; continue; }

    for path in "$user_agents" "$user_claude"; do
      if [[ ! -L "$path" ]]; then
        warn "Not a symlink: $path"
        fail=1
        continue
      fi
      local actual
      actual="$(resolve_path "$path")"
      if [[ "$actual" != "$expected" ]]; then
        warn "Symlink target mismatch: $path -> $actual (expected $expected)"
        fail=1
      else
        printf '[OK] %s -> %s\n' "$path" "$actual"
      fi
    done

    if [[ -n "$workspace_dir" ]]; then
      for path in "$workspace_dir/.agents/skills/$skill_name" "$workspace_dir/.claude/skills/$skill_name"; do
        if [[ ! -L "$path" ]]; then
          warn "Not a symlink: $path"
          fail=1
          continue
        fi
        local actual
        actual="$(resolve_path "$path")"
        if [[ "$actual" != "$expected" ]]; then
          warn "Symlink target mismatch: $path -> $actual (expected $expected)"
          fail=1
        else
          printf '[OK] %s -> %s\n' "$path" "$actual"
        fi
      done
    fi
  done < <(list_valid_skills "$skills_root")

  [[ "$count" -gt 0 ]] || die "No valid skills found under: $skills_root"
  [[ "$fail" -eq 0 ]] || die "Structural smoke tests failed"
}

run_cli_smoke_tests() {
  local workspace_dir="$1"
  printf '\n[SMOKE] CLI checks\n'

  if command -v gemini >/dev/null 2>&1; then
    log "Gemini CLI detected; running 'gemini skills list'"
    if [[ -n "$workspace_dir" ]]; then
      (cd "$workspace_dir" && gemini skills list) || warn "Gemini CLI exists but 'gemini skills list' failed"
    else
      gemini skills list || warn "Gemini CLI exists but 'gemini skills list' failed"
    fi
  else
    warn "Gemini CLI not found; skipped automatic Gemini smoke test"
  fi

  if command -v codex >/dev/null 2>&1; then
    log "Codex CLI detected"
    warn "Codex verification is interactive; open codex and run /skills"
  else
    warn "Codex CLI not found; skipped automatic Codex smoke test"
  fi

  if command -v claude >/dev/null 2>&1 || command -v claude-code >/dev/null 2>&1; then
    log "Claude Code CLI detected"
    warn "Claude verification is interactive; open claude and run /<skill-name>"
  else
    warn "Claude Code CLI not found; skipped automatic Claude smoke test"
  fi
}

print_manual_smoke_tests() {
  local workspace_dir="$1"
  cat <<TXT

Manual invocation smoke tests:

  Codex:
    cd "$workspace_dir"
    codex
    /skills

  Claude Code:
    cd "$workspace_dir"
    claude
    /<skill-name>

  Gemini CLI:
    cd "$workspace_dir"
    gemini skills list
    # or interactively:
    # /skills list
TXT
}

SKILLS_ROOT="$(abspath "$SKILLS_ROOT")"
WORKSPACE_DIR="$(resolve_workspace)"

log "Skills root : $SKILLS_ROOT"
if [[ -n "$WORKSPACE_DIR" ]]; then
  log "Workspace   : $WORKSPACE_DIR"
else
  log "Workspace   : disabled"
fi

ensure_dir "$SKILLS_ROOT"
init_skill_if_requested

# macOS still ships Bash 3.2, which does not provide `mapfile`.
SKILL_NAMES=()
while IFS= read -r skill_name; do
  [[ -n "$skill_name" ]] || continue
  SKILL_NAMES+=("$skill_name")
done < <(list_valid_skills "$SKILLS_ROOT")
[[ ${#SKILL_NAMES[@]} -gt 0 ]] || die "No valid skills found under: $SKILLS_ROOT"

log "Discovered ${#SKILL_NAMES[@]} valid skill(s)"
for skill_name in "${SKILL_NAMES[@]}"; do
  log "Syncing skill: $skill_name"
  create_or_update_link "$SKILLS_ROOT/$skill_name" "$HOME/.agents/skills/$skill_name"
  create_or_update_link "$SKILLS_ROOT/$skill_name" "$HOME/.claude/skills/$skill_name"

  if [[ -n "$WORKSPACE_DIR" ]]; then
    create_or_update_link "$SKILLS_ROOT/$skill_name" "$WORKSPACE_DIR/.agents/skills/$skill_name"
    create_or_update_link "$SKILLS_ROOT/$skill_name" "$WORKSPACE_DIR/.claude/skills/$skill_name"
  fi
done

run_structural_smoke_tests "$SKILLS_ROOT" "$WORKSPACE_DIR"
run_cli_smoke_tests "$WORKSPACE_DIR"
print_manual_smoke_tests "${WORKSPACE_DIR:-$(pwd)}"

printf '\n[DONE] Synced %s skill(s) from %s\n' "${#SKILL_NAMES[@]}" "$SKILLS_ROOT"
printf '[DONE] User Codex/Gemini path: %s\n' "$HOME/.agents/skills"
printf '[DONE] User Claude path: %s\n' "$HOME/.claude/skills"
