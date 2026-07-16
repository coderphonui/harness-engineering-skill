# AGENTS.md

<!-- Entry instruction file for AI coding agents. Keep it a router: 50–200 lines.
     Replace every {{placeholder}}. If a CLAUDE.md already exists, keep ONE canonical
     file and make the other a thin pointer to it. -->

{{One or two sentences: what this project is and its tech stack.}}

This repository is set up for long-running coding-agent work. The goal is not to maximize raw code
output; it is to leave the repo in a state where the next session can continue without guessing.

## Session Start

Before writing code:

1. Confirm the working directory with `pwd`.
2. Read `PROGRESS.md` for the latest verified state and next step.
3. Read `feature_list.json` and choose the highest-priority unfinished feature.
4. Review recent commits with `git log --oneline -5`.
5. Run `./init.sh` (installs dependencies and runs baseline verification).
6. If baseline verification is failing, fix that first — never stack new work on a broken start.

## Commands

- Setup: `{{install command}}`
- Dev server: `{{dev command}}`
- Tests: `{{test command}}`
- Full verification: `{{verify command — must pass before any commit}}`

## Hard Constraints

<!-- Max ~15 non-negotiable rules. Softer guidance goes in topic docs. -->

- {{hard constraint 1}}
- {{hard constraint 2}}
- Work on ONE feature at a time; the next feature unlocks only after the current one passes
  verification.
- Never mark a feature `passing` without running its verification command and recording evidence.
- Never weaken, skip, or delete tests to make work look complete.

## Topic Docs

<!-- One line + applicability condition each. The agent reads them on demand. -->

- `{{docs/architecture.md}}` — read before structural changes
- `{{docs/testing.md}}` — read when writing tests

## Definition of Done

A change is done only when ALL of the following hold:

- the target behavior is implemented
- the required verification actually ran and passed
- evidence is recorded in `feature_list.json` or `PROGRESS.md`
- the repository restarts cleanly from `./init.sh`

## Session End

1. Update `PROGRESS.md` (completed, verification run, evidence, risks, next best step).
2. Update `feature_list.json` states to reflect reality.
3. Remove temporary/debug artifacts.
4. Run full verification; commit safe work with a descriptive message.
5. Leave the repo so the next session can run `./init.sh` and continue immediately.
