#!/usr/bin/env bash
# harness-audit.sh — score a repository's agent harness across the five subsystems.
# Usage: bash harness-audit.sh [target-dir]   (default: current directory)
# Portable: bash 3.2+, no dependencies beyond coreutils/grep. Read-only.

set -u
TARGET="${1:-.}"
cd "$TARGET" 2>/dev/null || { echo "ERROR: cannot cd into '$TARGET'"; exit 2; }

PASS_MARK="[x]"
FAIL_MARK="[ ]"
TOTAL_PASS=0
TOTAL_CHECKS=0
SECTION_PASS=0
SECTION_CHECKS=0
REPORT=""
SUMMARY=""

# Locate the entry instruction file once.
ENTRY_FILE=""
for f in AGENTS.md CLAUDE.md .cursorrules; do
  [ -f "$f" ] && ENTRY_FILE="$f" && break
done

# Locate the progress file once.
PROGRESS_FILE=""
for f in PROGRESS.md claude-progress.md progress.md; do
  [ -f "$f" ] && PROGRESS_FILE="$f" && break
done

check() { # check "<label>" <0-pass|1-fail>
  local label="$1" result="$2"
  SECTION_CHECKS=$((SECTION_CHECKS + 1))
  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  if [ "$result" -eq 0 ]; then
    SECTION_PASS=$((SECTION_PASS + 1))
    TOTAL_PASS=$((TOTAL_PASS + 1))
    REPORT="$REPORT  $PASS_MARK $label\n"
  else
    REPORT="$REPORT  $FAIL_MARK $label\n"
  fi
}

begin_section() {
  REPORT="$REPORT\n## $1\n"
  SECTION_PASS=0
  SECTION_CHECKS=0
}

end_section() { # end_section "<name>"
  local score=0
  [ "$SECTION_CHECKS" -gt 0 ] && score=$(( (SECTION_PASS * 5 + SECTION_CHECKS / 2) / SECTION_CHECKS ))
  REPORT="$REPORT  Score: ${score}/5 (${SECTION_PASS}/${SECTION_CHECKS} checks)\n"
  SUMMARY="$SUMMARY$1|$score\n"
}

entry_grep() { # entry_grep "<pattern>" — case-insensitive grep in entry file
  [ -n "$ENTRY_FILE" ] && grep -qiE -e "$1" "$ENTRY_FILE"
}

any_exists() { # any_exists f1 f2 ... — succeed if at least one path exists
  local f
  for f in "$@"; do [ -e "$f" ] && return 0; done
  return 1
}

# ---------- 1. Instructions ----------
begin_section "Instructions"
[ -n "$ENTRY_FILE" ]; check "Entry instruction file exists (AGENTS.md / CLAUDE.md / .cursorrules)" $?
if [ -n "$ENTRY_FILE" ]; then
  LINES=$(wc -l < "$ENTRY_FILE" | tr -d ' ')
  [ "$LINES" -ge 20 ] && [ "$LINES" -le 300 ]; check "Entry file is router-sized (20-300 lines; found ${LINES:-0})" $?
  entry_grep "(overview|what (is|this)|purpose|platform|project)"; check "Entry file states what the project is" $?
  entry_grep "(hard constraint|must not|never|non-negotiable|MUST)"; check "Hard constraints are stated explicitly" $?
  entry_grep "\.md\)"; check "Entry file links to topic docs (routing, not encyclopedia)" $?
else
  check "Entry file is router-sized" 1
  check "Entry file states what the project is" 1
  check "Hard constraints are stated explicitly" 1
  check "Entry file links to topic docs" 1
fi
find . -maxdepth 4 -not -path './node_modules/*' -not -path './.git/*' \
  \( -name 'ARCHITECTURE.md' -o -name 'CONSTRAINTS.md' -o -name 'README.md' \) \
  -mindepth 2 2>/dev/null | grep -q . ; check "Module-level docs co-located with code" $?
end_section "Instructions"

# ---------- 2. Tools ----------
begin_section "Tools"
entry_grep '(pnpm|npm|yarn|bun|make|pytest|cargo|go test|gradle|mvn) '; check "Commands documented in entry file" $?
entry_grep "(lint|test|build|check|verify)"; check "Verification commands named in entry file" $?
[ -d ".claude" ] || [ -f ".mcp.json" ] || [ -d ".codex" ] || [ -f "Makefile" ]; check "Agent/tool configuration or task runner present" $?
end_section "Tools"

# ---------- 3. Environment ----------
begin_section "Environment"
any_exists package-lock.json pnpm-lock.yaml yarn.lock bun.lockb poetry.lock uv.lock Cargo.lock go.sum Gemfile.lock
check "Dependency lockfile present" $?
FOUND_PIN=1
any_exists .nvmrc .node-version .python-version .tool-versions .ruby-version && FOUND_PIN=0
[ "$FOUND_PIN" -ne 0 ] && [ -f package.json ] && grep -q '"engines"' package.json && FOUND_PIN=0
check "Runtime version pinned" $FOUND_PIN
[ -f "init.sh" ] || [ -f "Makefile" ] || { [ -f package.json ] && grep -q '"scripts"' package.json; }
check "Single-command setup path exists (init.sh / Makefile / package scripts)" $?
[ -f "init.sh" ]; check "init.sh startup+verification script present" $?
end_section "Environment"

# ---------- 4. State ----------
begin_section "State"
[ -n "$PROGRESS_FILE" ]; check "Progress log exists (PROGRESS.md or equivalent)" $?
if [ -n "$PROGRESS_FILE" ]; then
  grep -qiE "(current|verified) state" "$PROGRESS_FILE"; check "Progress log has a Current State block" $?
  grep -qiE "next (best )?(step|action)" "$PROGRESS_FILE"; check "Progress log records the next step" $?
else
  check "Progress log has a Current State block" 1
  check "Progress log records the next step" 1
fi
any_exists feature_list.json features.json docs/features.md || ls docs/features/*.md >/dev/null 2>&1
check "Feature list / scope surface exists" $?
if [ -f feature_list.json ]; then
  grep -q '"verification"' feature_list.json; check "Feature entries define verification" $?
  grep -q '"evidence"' feature_list.json; check "Feature entries have an evidence field" $?
elif ls docs/features/*.md >/dev/null 2>&1; then
  grep -qil "acceptance" docs/features/*.md 2>/dev/null; check "Feature entries define verification (acceptance criteria)" $?
  [ -n "$PROGRESS_FILE" ] && grep -qiE "evidence" "$PROGRESS_FILE"; check "Feature entries have an evidence field (evidence in progress log)" $?
else
  check "Feature entries define verification" 1
  check "Feature entries have an evidence field" 1
fi
any_exists DECISIONS.md docs/decisions || { [ -n "$PROGRESS_FILE" ] && grep -qiE "decision" "$PROGRESS_FILE"; }
check "Decision rationale captured (DECISIONS.md or in progress log)" $?
any_exists session-handoff.md templates/session-handoff.md docs/harness/session-handoff.md; check "Session handoff template present" $?
end_section "State"

# ---------- 5. Feedback ----------
begin_section "Feedback"
entry_grep "(definition of done|done only when|completion (gate|criteria))"; check "Definition of done documented" $?
entry_grep "(one feature at a time|single active|WIP ?= ?1|one task at a time)"; check "WIP=1 rule stated" $?
entry_grep "(session start|startup workflow|before writing code|clock.?in|at the start of every session)"; check "Session-start routine documented" $?
entry_grep "(session end|before ending|end of session|clock.?out|before you stop)"; check "Session-end routine documented" $?
any_exists clean-state-checklist.md templates/clean-state-checklist.md docs/harness/clean-state-checklist.md || entry_grep "clean state"
check "Clean-state / exit checklist exists" $?
any_exists evaluator-rubric.md templates/evaluator-rubric.md docs/harness/evaluator-rubric.md; check "Evaluator rubric present (maker != checker)" $?
any_exists quality-document.md QUALITY_SCORE.md docs/QUALITY_SCORE.md docs/harness/quality-document.md; check "Quality document tracks codebase health" $?
entry_grep "(evidence|verification (actually )?ran|runnable proof)"; check "Evidence required before claiming done" $?
end_section "Feedback"

# ---------- 6. Monorepo (only when workspace markers exist) ----------
MONOREPO=1
any_exists pnpm-workspace.yaml turbo.json nx.json lerna.json rush.json go.work melos.yaml && MONOREPO=0
[ "$MONOREPO" -ne 0 ] && [ -f package.json ] && grep -q '"workspaces"' package.json && MONOREPO=0
[ "$MONOREPO" -ne 0 ] && [ -f Cargo.toml ] && grep -q '^\[workspace\]' Cargo.toml && MONOREPO=0

if [ "$MONOREPO" -eq 0 ]; then
  begin_section "Monorepo"

  # Enumerate workspace packages under the common layout directories.
  APP_DIRS=""
  for d in apps/* services/* packages/* libs/* crates/*; do
    [ -d "$d" ] || continue
    if [ -f "$d/package.json" ] || [ -f "$d/pyproject.toml" ] || [ -f "$d/Cargo.toml" ] || \
       [ -f "$d/go.mod" ] || [ -f "$d/pubspec.yaml" ]; then
      APP_DIRS="$APP_DIRS $d"
    fi
  done
  APP_COUNT=0
  ENTRY_COUNT=0
  MISSING_ENTRIES=""
  for d in $APP_DIRS; do
    APP_COUNT=$((APP_COUNT + 1))
    if [ -f "$d/AGENTS.md" ] || [ -f "$d/CLAUDE.md" ]; then
      ENTRY_COUNT=$((ENTRY_COUNT + 1))
    else
      MISSING_ENTRIES="$MISSING_ENTRIES $d"
    fi
  done

  entry_grep "(monorepo|workspace|apps/|packages/|services/)"
  check "Root entry file describes the workspace layout" $?
  entry_grep "(triage|change.?scope|scope triage|affects|which app|cross.?app)"
  check "Change-scope triage documented in root entry file" $?
  [ "$APP_COUNT" -gt 0 ] && [ "$ENTRY_COUNT" -eq "$APP_COUNT" ]
  check "Every workspace package has a nested entry file (${ENTRY_COUNT}/${APP_COUNT}${MISSING_ENTRIES:+; missing:${MISSING_ENTRIES}})" $?
  entry_grep "(--filter|filter=|workspace|turbo|nx (run|affected)|cargo -p|pnpm -r|npm -w|yarn workspace|go test \./)"
  check "Per-app filtered commands documented" $?
  entry_grep "(repo root|root (command|verification|gate)|all (apps|packages)|fan.?out)"
  check "Root-level verification gate named as the definition-of-done" $?
  BOUNDARY=1
  any_exists .dependency-cruiser.js .dependency-cruiser.cjs .dependency-cruiser.json && BOUNDARY=0
  [ "$BOUNDARY" -ne 0 ] && grep -qriE "no-restricted-paths|enforce-module-boundaries" \
    .eslintrc* eslint.config.* nx.json 2>/dev/null && BOUNDARY=0
  check "Boundary rules mechanically enforced (dependency-cruiser / eslint / nx boundaries)" $BOUNDARY

  end_section "Monorepo"
fi

# ---------- 7. Lifecycle (only when the project has opted in) ----------
LIFECYCLE=1
if [ -f feature_list.json ] && grep -q '"lifecycle"' feature_list.json && \
   grep -A2 '"lifecycle"' feature_list.json | grep -q '"enabled": *true'; then
  LIFECYCLE=0
fi
[ "$LIFECYCLE" -ne 0 ] && [ -d docs/features ] && ls docs/features/*/brief.md >/dev/null 2>&1 && LIFECYCLE=0

if [ "$LIFECYCLE" -eq 0 ]; then
  begin_section "Lifecycle"

  grep -q '"lifecycle"' feature_list.json 2>/dev/null && \
    grep -A2 '"lifecycle"' feature_list.json | grep -q '"enabled": *true'
  check "Lifecycle enabled in feature_list.json rules" $?
  [ -d docs/features ]; check "docs/features/ stage-doc directory exists" $?
  # Every feature doc dir should carry at least brief.md and spec.md.
  DOC_DIRS=0; DOC_OK=0
  for d in docs/features/*/; do
    [ -d "$d" ] || continue
    DOC_DIRS=$((DOC_DIRS + 1))
    [ -f "${d}brief.md" ] && [ -f "${d}spec.md" ] && DOC_OK=$((DOC_OK + 1))
  done
  [ "$DOC_DIRS" -gt 0 ] && [ "$DOC_OK" -eq "$DOC_DIRS" ]
  check "Feature doc dirs have stage artifacts (${DOC_OK}/${DOC_DIRS} with brief+spec)" $?
  grep -q '"last_verification"' feature_list.json 2>/dev/null || \
    grep -q 'verify PASS' feature_list.json 2>/dev/null
  check "Verification runs recorded on entries (evidence of gated transitions)" $?
  grep -qri "^Verdict:" docs/features/*/review.md 2>/dev/null
  check "QA reviews carry explicit verdicts (maker != checker gate in use)" $?

  end_section "Lifecycle"
fi

# ---------- Report ----------
echo "# Harness Audit: $(basename "$(pwd)")"
echo
echo "Overall: ${TOTAL_PASS}/${TOTAL_CHECKS} checks passed"
printf '%b' "$REPORT"
echo
echo "## Subsystem Scores"
WEAKEST_NAME=""
WEAKEST_SCORE=6
while IFS='|' read -r name score; do
  [ -z "$name" ] && continue
  echo "  $name: $score/5"
  if [ "$score" -lt "$WEAKEST_SCORE" ]; then
    WEAKEST_SCORE=$score
    WEAKEST_NAME=$name
  fi
done <<EOF
$(printf '%b' "$SUMMARY")
EOF
echo
echo "Weakest subsystem: $WEAKEST_NAME ($WEAKEST_SCORE/5)"
echo "Note: the lowest score is a CANDIDATE bottleneck. Confirm against actual failure"
echo "history before investing. See references/audit.md for the manual checklist."
