# Session Protocol

The fixed start/end routine for agent work sessions in a harnessed repository, plus the
initialization playbook for new projects. Applies to any agent (Claude Code, Codex, Cursor, …).

## Session Start (clock in)

Run these steps in order, before writing any code:

1. `pwd` — confirm the expected repository root. Prevents work in the wrong directory.
2. Read `PROGRESS.md` (or `claude-progress.md`) — current verified state and next best step.
3. Read `feature_list.json` — feature states; identify the highest-priority unfinished feature.
4. `git log --oneline -5` — what changed most recently.
5. Run `./init.sh` (or the documented setup + verification commands).
6. Run the baseline smoke/verification path.
7. **If the baseline is already broken, fix that first.** Never stack new feature work on a broken
   starting state — new work will hide the breakage.
8. Select exactly ONE unfinished feature. Work only on it until verified or explicitly blocked.
9. **Monorepo only**: read the nested entry file of every app the feature's `affects` lists, and
   run change-scope triage if `affects` is empty or the feature might cross an app contract
   (see [monorepo.md](monorepo.md)). The baseline check in steps 5–6 is the ROOT verification,
   covering all apps — a broken app blocks feature work even in a different app.

Why this order: cwd → durable state → recent history → standardized boot → baseline check. Each
step removes a class of guessing before the expensive work begins. A good harness gets a fresh
session to an executable state in under ~3 minutes.

## During the Session

- WIP=1: no side-quests, no "refactor while we're at it" until the active feature passes.
- Commit after each atomic unit of work; the message explains what and why.
- Record design decisions (what, why, rejected alternatives) in the progress log as they happen —
  the "why" is what gets lost between sessions.
- If the task will need more than ~60% of the context window, start preparing the handoff early
  rather than rushing at the end (counteracts "context anxiety": the tendency to skip verification
  and choose easy paths when context runs low).

## Session End (clock out)

A session is complete only when the task is verified AND the clean state check passes:

1. Update `PROGRESS.md`: completed, verification run, evidence, known risks, next best step.
2. Update `feature_list.json` states — reflecting what is *actually* passing vs. unverified.
   Never rewrite states to hide unfinished work.
3. Remove temporary artifacts: debug logs, scratch files, commented-out code, leftover `console.log`.
4. Run the full verification path; build and tests must be green.
5. Commit safe work with a descriptive message.
6. For long or multi-area sessions, write `session-handoff.md` (verified now / changed / broken or
   unverified / next best step / commands).

### Clean State Checklist

- [ ] Standard startup path still works
- [ ] Standard verification path passes
- [ ] Progress log updated
- [ ] Feature list reflects reality (no false `passing`)
- [ ] No half-finished step left undocumented
- [ ] No stale temp/debug artifacts
- [ ] Next session can continue without manual repair

Skipping cleanup compounds: the next session sees mess, assumes mess is acceptable, and adds more
(measured over 12 weeks: no-cleanup projects fell to 68% build pass rate and 60+ min session
startup; cleanup-disciplined projects held 97% and 9 min).

## Compaction vs. Reset

When context runs out mid-task, two options:

- **Compaction** (summarize in-session): keeps continuity but loses the "why"; residual context
  anxiety remains.
- **Reset** (new session from artifacts): clean mental state, but only as good as the handoff
  artifacts.

Prefer reset when handoff artifacts are complete; that's what the protocol above guarantees.
Short tasks (< ~30 min) can just complete in-session without ceremony.

## Initialization Playbook (first session in a new project)

The first serious session does **only** initialization — zero business feature code. Its output is
infrastructure:

1. Runnable environment (dependencies installed, project starts).
2. Verifiable test framework — at least one example test passing (proves the framework works).
3. Startup-readiness doc: start/test/verify commands, current state, project structure.
4. Task breakdown: ordered feature list with acceptance criteria per feature.
5. A clean baseline git commit.

Start from a template (framework starter, this skill's `assets/templates/`), not an empty
directory. Acceptance checklist:

- [ ] Setup command succeeds from scratch
- [ ] At least one test passes
- [ ] A fresh agent session can answer "how to run" and "how to verify" from repo contents alone
- [ ] Task breakdown exists with ≥3 features and acceptance criteria
- [ ] Everything committed

The time spent is recovered within 3–4 sessions; skipping it means every later session pays the
discovery cost again, and unrecorded initialization decisions (test framework choice, directory
conventions) get silently contradicted by later sessions.

## Multi-Agent / Parallel Work

- Each parallel agent works in its own git worktree or branch — physical isolation beats politeness.
- Each agent has its own progress file section or file; never concurrent writes to one state file.
- Review bandwidth is the real ceiling: run only as many parallel agents as outputs you can
  actually review.
