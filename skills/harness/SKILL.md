---
name: harness
description: >-
  Audit, scaffold, and operate harness engineering best practices for any repository — the
  engineering infrastructure that makes AI coding agents reliable: entry instruction files
  (AGENTS.md/CLAUDE.md), machine-readable feature lists, progress logs, init/verification scripts,
  session start/exit protocols, maker-checker verification, and autonomous loops. Covers both
  single-package repositories and monorepos (per-app harness at the application level). Use when:
  (1) starting long or multi-session agent work, (2) an agent forgets context between sessions,
  drifts out of scope, or claims "done" before verification passes, (3) creating or improving
  AGENTS.md, CLAUDE.md, feature_list.json, PROGRESS.md, init.sh, or session-handoff files,
  (4) the user asks for a harness audit, harness setup, session handoff, definition of done,
  or an automated/scheduled agent loop, (5) setting up per-app instructions and verification in a
  monorepo. Agent-agnostic: works with Claude Code, Codex, Cursor, or any coding agent that can
  read repository files.
---

# Harness Engineering

A harness is **everything outside the model weights**: instructions, tools, environment, state, and
feedback. When an agent fails, fix the harness first — don't swap the model. This skill turns the
harness engineering methodology (OpenAI Codex practices, Anthropic long-running-agent research,
learn-harness-engineering course) into concrete operations for the repository you are working in.

Everything this skill produces is **plain repository files** readable by any agent. Never encode
harness rules only in chat history, memory, or tool-specific config — if it is not in the repo, it
does not exist for the next session or for a different agent.

**First step, always**: identify the target repository's shape. If it contains workspace markers
(`pnpm-workspace.yaml`, `workspaces` in `package.json`, `turbo.json`, `nx.json`, `lerna.json`,
`go.work`, a `[workspace]` Cargo.toml, multiple deployable apps under `apps/`), it is a
**monorepo** — read [references/monorepo.md](references/monorepo.md) before any mode below, and
apply every subsystem at BOTH the root level and the application level.

## The Five Subsystems

Every reliable harness has all five. A missing subsystem is the first thing to fix.

| Subsystem | Artifact | Answers |
|---|---|---|
| Instructions | `AGENTS.md` / `CLAUDE.md` (router, 50–200 lines) + topic docs | What is this project? What are the hard rules? |
| Tools | Documented commands, scoped permissions | What can I run? |
| Environment | `init.sh`, lockfiles, pinned versions | How do I get to a working baseline? |
| State | `PROGRESS.md`, `feature_list.json`, git checkpoints | What is done, in progress, blocked, next? |
| Feedback | Explicit verification commands, definition of done | How do I know it worked? |

Feedback is the highest-ROI subsystem: get verification commands explicit and runnable first.
In a monorepo, each subsystem has a root layer (cross-cutting) and an app layer (per deployable) —
see the two-level matrix in [references/monorepo.md](references/monorepo.md).

## Modes

Pick the mode matching the request. Each mode routes to a reference file — read it before acting.

### 1. Audit — "How good is our harness?"

Run the bundled audit script (it lives next to this SKILL.md; resolve the path from wherever the
skill is installed, e.g. `.claude/skills/harness/` for Claude Code or `.codex/skills/harness/` for
Codex):

```bash
bash <skill-dir>/scripts/harness-audit.sh [target-dir]
```

The script auto-detects monorepos and adds per-app checks. Report the per-subsystem scores, the
weakest subsystem, and the 2–3 highest-impact fixes. Treat the lowest score as a *candidate*
bottleneck — confirm against actual failure history before claiming causality. For the full manual
checklist and scoring rubric, read [references/audit.md](references/audit.md).

### 2. Scaffold — "Set up the harness"

Copy and adapt templates from `assets/templates/` into the target repository:

1. Inspect what already exists (entry files, verify commands, state files). Never overwrite an
   existing file without explicit user approval.
2. Create the missing artifacts, adapted to the project's real commands and structure:
   `AGENTS.md` (or extend the existing entry file), `PROGRESS.md`, `feature_list.json`, `init.sh`.
   Add `session-handoff.md`, `evaluator-rubric.md`, `quality-document.md` as the project grows.
   In a monorepo, additionally create a nested entry file per app from `AGENTS.app.md` and follow
   the scaffold order in [references/monorepo.md](references/monorepo.md).
3. Replace every placeholder with real project values — a template with placeholders left in is
   worse than no template.
4. Wire the session protocol (startup + exit steps) into the entry file.
5. Commit the scaffold as a clean baseline checkpoint.

For a brand-new project, run a **dedicated initialization session** before any feature work:
environment runnable, one example test passing, task breakdown written, baseline committed.
Details and acceptance checklist: [references/session-protocol.md](references/session-protocol.md).

### 3. Operate — session start / session end

When beginning or ending a stretch of agent work in a harnessed repo, follow the fixed protocol in
[references/session-protocol.md](references/session-protocol.md). Summary:

- **Start**: confirm cwd → read progress log → read feature list → `git log --oneline -5` →
  run init/verify → if baseline broken, fix that first → select ONE feature. In a monorepo, also
  read the nested entry file of every app the feature touches.
- **End**: update progress log and feature list → clean temp artifacts → verify build+tests green →
  commit → leave a restartable state. A session is not done until the clean-state checklist passes.

### 4. Verify — "Is this actually done?"

Before accepting any completion claim (your own or another agent's), apply the verification gates
in [references/verification.md](references/verification.md). Summary: done = evidence, not
confidence. Three layers (static → runtime → end-to-end), no layer skipped; the maker never grades
its own work; error messages state WHAT / WHY / FIX. In a monorepo, the definition-of-done gate is
always the root-level verification command, never a single app's filtered command.

### 5. Loop — "Make it run without me"

When the user wants recurring, scheduled, or goal-driven autonomous work, read
[references/loop-engineering.md](references/loop-engineering.md). Summary: a loop = goal +
verification + stopping condition; separate maker from checker; persist state to disk between
runs; watch the four silent costs.

### 6. Lifecycle (opt-in) — "Take a feature from idea to shipped"

When the project opts in (`rules.lifecycle.enabled` in `feature_list.json`), features flow through
staged, gated phases: **brainstorm & analyze → requirement spec → technical design →
implementation → QA & code review**, each with a named artifact (`docs/features/<id>/brief.md`,
`spec.md`, `design.md`, `review.md`) and a machine-checked exit gate. The bundled tool
`scripts/feature.py` (Python 3, stdlib only) mechanizes creation, gated stage transitions,
verification runs, and blocking — but it is an accelerator, not a dependency: every operation is
a hand-editable file change. Small features use `light` tier and skip straight to the classic
`not_started → in_progress → passing` flow; with the lifecycle off, the whole skill behaves as if
this mode didn't exist. Read [references/feature-lifecycle.md](references/feature-lifecycle.md)
before operating this mode.

## Core Concepts

For the distilled methodology behind all modes — failure taxonomy, repo-as-system-of-record,
instruction splitting, WIP=1, feature lists as primitives, observability, clean state, harness
simplification — read [references/principles.md](references/principles.md). Read it when designing
or explaining harness decisions, not for routine operation.

## Design Rules (non-negotiable)

1. **Repo is the system of record.** Knowledge not in the repo does not exist for the agent.
2. **Entry file is a router, not an encyclopedia.** 50–200 lines; details in linked topic docs.
   Critical constraints go at the top or bottom of a file, never the middle (lost-in-the-middle).
3. **WIP = 1.** One feature active at a time. No "refactor while we're at it" until the current
   feature passes verification.
4. **Done = evidence.** A feature is `passing` only when its verification command actually ran and
   the result is recorded. Never mark passing from code inspection.
5. **State transitions are gated.** Never edit feature states to hide unfinished work, and never
   weaken or delete tests to make work look complete.
6. **Maker ≠ checker.** Completion judgment comes from an independent run, evaluator agent, or
   script — never from the session that wrote the code.
7. **Every session leaves a clean state.** Build green, tests green, progress recorded, temp
   artifacts removed, standard startup path works.
8. **Promote repeated feedback into mechanical checks.** The same review comment twice → a lint
   rule, test, or script with a WHAT/WHY/FIX error message.
9. **Smallest artifact that fixes the observed failure.** Don't answer every failure by growing the
   entry file; map the failure to a subsystem and fix that subsystem.
10. **Periodically simplify.** Each harness component encodes an assumption about what models can't
    do. Re-test those assumptions; remove components that no longer earn their cost.
11. **In a monorepo, detail lives at the app level.** The root entry file routes and holds
    cross-cutting rules only; per-app architecture, commands, gotchas, and definition-of-done
    detail live in that app's nested entry file.

## Failure → Fix Map

When the user describes a symptom, jump straight to the fix:

| Symptom | Fix first | Artifact |
|---|---|---|
| New session wastes time rediscovering the project | System of record | `PROGRESS.md`, entry file |
| Starts many things, finishes none | WIP=1 + scope surface | `feature_list.json` |
| Claims done, but it isn't | Evidence-gated completion | verification commands, rubric |
| Every session re-learns how to boot | Standardized startup | `init.sh` |
| Next session can't tell what's verified/broken | Explicit handoff | `session-handoff.md` |
| Repo quality degrades over weeks | Clean-state exit + cleanup loop | checklist, `quality-document.md` |
| Same mistake keeps recurring | Review-feedback promotion | lint/test with WHAT/WHY/FIX |
| Human is the bottleneck pressing "go" | Loop engineering | see loop reference |
| Change in one app silently breaks another | Change-scope triage + contract checks | see monorepo reference |
| Root entry file balloons with per-app detail | Two-level instruction architecture | nested entry files |
| Coding starts before requirements are agreed, causing rework | Staged lifecycle with gates | see feature-lifecycle reference |

## Project-Specific Bindings

This skill ships generic. On first serious use in a repository, record that repository's concrete
bindings **in the repository itself** (entry file or a linked topic doc), never in this skill:
the canonical entry file name, the exact root verification command, the state artifacts in use and
where they live, and — for monorepos — the app list and each app's filtered commands. If you find
project-specific facts inside this skill's files, that is contamination from a previous project:
remove them and relocate anything still true into that project's own files.

## Agent Portability

This skill and its outputs must work for any coding agent:

- Claude Code and Codex both read this SKILL.md format natively (`/harness` or `$harness`) when the
  skill is installed in their skill directory (`.claude/skills/harness/`, `.codex/skills/harness/`).
  The repo this skill ships from provides an `install.sh` that copies it into place.
- For agents without skill support (Cursor, Windsurf, custom SDK agents): the harness artifacts
  themselves (`AGENTS.md`, `feature_list.json`, `PROGRESS.md`, `init.sh`) are the interface — add
  one line to the agent's rules file (e.g. `.cursorrules`): "Follow the startup and exit protocol
  in AGENTS.md."
- Never rely on tool-specific features (hooks, MCP, slash commands) for correctness; use them only
  as accelerators on top of the file-based harness.
