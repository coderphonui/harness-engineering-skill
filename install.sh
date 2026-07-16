#!/usr/bin/env bash
# install.sh — install the harness skill into a target repository for one or more agents.
# Portable: bash 3.2+, coreutils only.
#
# Usage:
#   ./install.sh <target-repo> [--claude] [--codex] [--generic] [--all] [--dir <path>] [--force]
#
#   --claude   install to <target>/.claude/skills/harness   (Claude Code — default)
#   --codex    install to <target>/.codex/skills/harness    (OpenAI Codex CLI)
#   --generic  install to <target>/.agents/skills/harness   (cross-agent Agent Skills convention)
#   --all      all three of the above
#   --dir P    install to <target>/P/harness (custom skill directory, repeatable)
#   --force    overwrite an existing installation
set -euo pipefail

SKILL_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills/harness"

usage() {
  sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

TARGET=""
DESTS=""
FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --claude)  DESTS="$DESTS .claude/skills" ;;
    --codex)   DESTS="$DESTS .codex/skills" ;;
    --generic) DESTS="$DESTS .agents/skills" ;;
    --all)     DESTS=".claude/skills .codex/skills .agents/skills" ;;
    --dir)     shift; [ $# -gt 0 ] || { echo "ERROR: --dir needs a path"; exit 2; }
               DESTS="$DESTS $1" ;;
    --force)   FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    -*)        echo "ERROR: unknown flag '$1'"; usage; exit 2 ;;
    *)         [ -z "$TARGET" ] || { echo "ERROR: multiple targets given"; exit 2; }
               TARGET="$1" ;;
  esac
  shift
done

[ -n "$TARGET" ] || { usage; exit 2; }
[ -d "$TARGET" ] || { echo "ERROR: target '$TARGET' is not a directory"; exit 2; }
[ -f "$SKILL_SRC/SKILL.md" ] || { echo "ERROR: skill source not found at $SKILL_SRC"; exit 2; }
[ -n "$DESTS" ] || DESTS=".claude/skills"

INSTALLED=""
for dest in $DESTS; do
  full="$TARGET/$dest/harness"
  if [ -e "$full" ] && [ "$FORCE" -ne 1 ]; then
    echo "SKIP  $full already exists (use --force to overwrite)"
    continue
  fi
  mkdir -p "$full"
  # Copy contents; clean first on --force so removed files don't linger.
  [ "$FORCE" -eq 1 ] && rm -rf "$full" && mkdir -p "$full"
  cp -R "$SKILL_SRC/." "$full/"
  chmod +x "$full/scripts/harness-audit.sh" 2>/dev/null || true
  echo "OK    installed to $full"
  INSTALLED="$INSTALLED $full"
done

[ -n "$INSTALLED" ] || { echo "Nothing installed."; exit 1; }

cat <<'EOF'

Next steps
----------
1. Audit the target repo:
     bash <install-path>/scripts/harness-audit.sh <target-repo>
2. Invoke the skill from your agent:
     Claude Code:  /harness        Codex:  $harness
3. Agents without skill support (Cursor, Windsurf, custom SDK agents): the harness
   artifacts the skill scaffolds (AGENTS.md, PROGRESS.md, feature_list.json, init.sh)
   are the interface — add one line to the agent's rules file, e.g. in .cursorrules:
     "Follow the startup and exit protocol in AGENTS.md."
4. Monorepo? The skill detects workspace markers and applies per-app harness rules
   automatically; see references/monorepo.md in the installed skill.
EOF
