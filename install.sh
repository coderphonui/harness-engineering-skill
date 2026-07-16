#!/usr/bin/env bash
# install.sh — install the harness skill family into a target repository for one or more agents.
# Installs every skill under skills/ (harness + the feature lifecycle stage skills).
# Portable: bash 3.2+, coreutils only.
#
# Usage:
#   ./install.sh <target-repo> [--claude] [--codex] [--generic] [--all] [--dir <path>]
#                [--only <name>] [--force] [--symlink]
#
#   --claude    install to <target>/.claude/skills/   (Claude Code — default)
#   --codex     install to <target>/.codex/skills/    (OpenAI Codex CLI)
#   --generic   install to <target>/.agents/skills/   (cross-agent Agent Skills convention)
#   --all       all three of the above
#   --dir P     install to <target>/P/ (custom skill directory, repeatable)
#   --only N    install just skill N (e.g. --only harness); repeatable
#   --force     overwrite existing installations
#   --symlink   symlink each skill dir instead of copying (default: copy)
set -euo pipefail

SRC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills"

usage() {
  sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

TARGET=""
DESTS=""
ONLY=""
FORCE=0
SYMLINK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --claude)  DESTS="$DESTS .claude/skills" ;;
    --codex)   DESTS="$DESTS .codex/skills" ;;
    --generic) DESTS="$DESTS .agents/skills" ;;
    --all)     DESTS=".claude/skills .codex/skills .agents/skills" ;;
    --dir)     shift; [ $# -gt 0 ] || { echo "ERROR: --dir needs a path"; exit 2; }
               DESTS="$DESTS $1" ;;
    --only)    shift; [ $# -gt 0 ] || { echo "ERROR: --only needs a skill name"; exit 2; }
               ONLY="$ONLY $1" ;;
    --force)   FORCE=1 ;;
    --symlink) SYMLINK=1 ;;
    -h|--help) usage; exit 0 ;;
    -*)        echo "ERROR: unknown flag '$1'"; usage; exit 2 ;;
    *)         [ -z "$TARGET" ] || { echo "ERROR: multiple targets given"; exit 2; }
               TARGET="$1" ;;
  esac
  shift
done

[ -n "$TARGET" ] || { usage; exit 2; }
[ -d "$TARGET" ] || { echo "ERROR: target '$TARGET' is not a directory"; exit 2; }
[ -d "$SRC_ROOT" ] || { echo "ERROR: skill source not found at $SRC_ROOT"; exit 2; }
[ -n "$DESTS" ] || DESTS=".claude/skills"

want() { # want <name> — true when no --only filter, or name was selected
  [ -z "$ONLY" ] && return 0
  local n
  for n in $ONLY; do [ "$n" = "$1" ] && return 0; done
  return 1
}

INSTALLED=""
for dest in $DESTS; do
  for skill_dir in "$SRC_ROOT"/*/; do
    name="$(basename "$skill_dir")"
    [ -f "$skill_dir/SKILL.md" ] || continue
    want "$name" || continue
    full="$TARGET/$dest/$name"
    if [ -e "$full" ] || [ -L "$full" ]; then
      if [ "$FORCE" -ne 1 ]; then
        echo "SKIP  $full already exists (use --force to overwrite)"
        continue
      fi
      # Clean first on --force so removed files don't linger.
      rm -rf "$full"
    fi
    if [ "$SYMLINK" -eq 1 ]; then
      mkdir -p "$(dirname "$full")"
      ln -s "${skill_dir%/}" "$full"
      echo "OK    symlinked $name -> $full"
    else
      mkdir -p "$full"
      cp -R "$skill_dir." "$full/"
      find "$full" \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} + 2>/dev/null || true
      echo "OK    installed $name -> $full"
    fi
    INSTALLED="$INSTALLED $name"
  done
done

[ -n "$INSTALLED" ] || { echo "Nothing installed."; exit 1; }

cat <<'EOF'

Next steps
----------
1. Audit the target repo:
     bash <skills-path>/harness/scripts/harness-audit.sh <target-repo>
2. Invoke from your agent:
     Claude Code:  /harness  /feature  /feature-spec ...    Codex:  $harness  $feature ...
   The feature lifecycle stage skills (feature-brainstorm, feature-spec, feature-design,
   feature-implement, feature-review) reference the harness skill by relative path — keep the
   family installed side by side.
3. Agents without skill support (Cursor, Windsurf, custom SDK agents): the harness
   artifacts the skill scaffolds (AGENTS.md, PROGRESS.md, feature_list.json, init.sh)
   are the interface — add one line to the agent's rules file, e.g. in .cursorrules:
     "Follow the startup and exit protocol in AGENTS.md."
4. Monorepo? The harness skill detects workspace markers and applies per-app rules
   automatically; see harness/references/monorepo.md.
EOF
