# harness-skill

A portable, agent-agnostic **skill** that audits, scaffolds, and operates *harness engineering*
best practices in any repository — the infrastructure that makes AI coding agents reliable across
long and multi-session work.

A "harness" is everything outside the model weights: instructions, tools, environment, state, and
feedback. The same model, in a bare repo vs. a harnessed one, produces qualitatively different
results — the model doesn't get better, the conditions it operates in do. This skill packages that
methodology — most directly the
[Learn Harness Engineering](https://walkinglabs.github.io/learn-harness-engineering/en/) course,
alongside OpenAI Codex practices, Anthropic's long-running-agent research, and Addy Osmani's Loop
Engineering — into concrete files any coding agent can read and act on: entry instruction files,
machine-readable feature lists, progress logs, init/verification scripts, session start/exit
protocols, maker-checker verification, and autonomous loops.

Single-package repositories and monorepos are both covered. In a monorepo every subsystem is
applied at the root level *and* at the application level — see [Monorepos](#monorepos).

## Table of Contents

- [Quick Start](#quick-start)
- [Layout](#layout)
- [Usage](#usage)
- [The Five Subsystems](#the-five-subsystems)
- [Feature Development Lifecycle (opt-in)](#feature-development-lifecycle-opt-in)
- [Monorepos](#monorepos)
- [Design Principles](#design-principles)
- [Requirements](#requirements)
- [Updating / Uninstalling](#updating--uninstalling)
- [Extending the Skill](#extending-the-skill)
- [FAQ](#faq)
- [Credits](#credits)

## Quick Start

```bash
# 1. Install into a target repository (whole family: harness + feature stage skills)
./install.sh /path/to/your-repo              # Claude Code: .claude/skills/

# 2. See where its harness currently stands
bash /path/to/your-repo/.claude/skills/harness/scripts/harness-audit.sh /path/to/your-repo

# 3. Ask your agent to act on the findings
#      Claude Code:  /harness            Codex:  $harness
#      "audit our harness" / "set up the harness" / "is this actually done?"
```

The audit script is read-only and reports a score per subsystem, e.g.:

```
# Harness Audit: your-repo

Overall: 16/35 checks passed
...
## Subsystem Scores
  Instructions: 3/5
  Tools: 3/5
  Environment: 1/5
  State: 0/5
  Feedback: 4/5

Weakest subsystem: State (0/5)
Note: the lowest score is a CANDIDATE bottleneck. Confirm against actual failure
history before investing. See references/audit.md for the manual checklist.
```

From there, ask the agent to **scaffold** the missing pieces — it adapts the templates in
`assets/templates/` to your project's real commands and structure rather than leaving placeholders.

## Layout

```
skills/
├── feature/                        # lifecycle dispatcher: routes a feature to its stage skill
├── feature-brainstorm/             # stage skill: product analyst — brief.md
├── feature-spec/                   # stage skill: requirements engineer — spec.md
├── feature-design/                 # stage skill: software architect — design.md
├── feature-implement/              # stage skill: disciplined implementer — code + evidence
├── feature-review/                 # stage skill: independent checker — review.md verdict
└── harness/                        # the core skill (audit / scaffold / operate / verify / loop)
skills/harness/
├── SKILL.md                        # entry point (Claude Code /harness, Codex $harness)
├── references/
│   ├── principles.md               # distilled methodology — read to design or explain a decision
│   ├── audit.md                    # manual audit checklist + scoring rubric behind the script
│   ├── monorepo.md                 # two-level harness rules for monorepos
│   ├── feature-lifecycle.md        # opt-in staged lifecycle (brainstorm → spec → design → impl → QA)
│   ├── verification.md             # definition of done, maker ≠ checker, WHAT/WHY/FIX errors
│   ├── session-protocol.md         # session start/end routine, new-project initialization playbook
│   └── loop-engineering.md         # autonomous / scheduled / goal-driven agent loops
├── scripts/
│   ├── harness-audit.sh            # mechanical, read-only audit (auto-detects monorepos + lifecycle)
│   └── feature.py                  # feature-list manager + gated lifecycle transitions (py3 stdlib)
└── assets/templates/
    ├── AGENTS.md                   # entry instruction file (router) for a single-package repo
    ├── AGENTS.app.md               # nested per-app entry file for a monorepo
    ├── feature_list.json           # machine-readable scope surface + state machine
    ├── PROGRESS.md                 # cross-session state: current verified state, decisions, log
    ├── init.sh                     # single-command startup + baseline verification
    ├── session-handoff.md          # end-of-session handoff for long/multi-area work
    ├── evaluator-rubric.md         # independent completion scoring (maker ≠ checker)
    ├── quality-document.md         # codebase health grade over time, per domain/layer
    ├── sprint-contract.md          # scope agreed before implementation begins
    ├── clean-state-checklist.md    # session-exit gate
    └── lifecycle/                  # stage docs: brief.md, spec.md, design.md, review.md
install.sh                          # copies the skill into a target repo, for one or more agents
README.md                           # this file
```

Each reference file is self-contained and linked from `SKILL.md` — read the one that matches the
mode you're in, not all of them up front.

## Usage

The skill has five modes; ask for any of them in plain language and it reads the matching
reference file before acting:

| Mode | Ask | What happens | Reference |
|---|---|---|---|
| Audit | "How good is our harness?" | Runs `scripts/harness-audit.sh`, scores the five subsystems, names the weakest + top 2–3 fixes | `references/audit.md` |
| Scaffold | "Set up the harness" | Copies/adapts templates: entry file(s), feature list, progress log, `init.sh` — never overwrites existing files without approval | `SKILL.md` §2 |
| Operate | session start / session end | Fixed clock-in (cwd → progress → features → recent commits → baseline verify) / clock-out (update state → clean temp artifacts → verify → commit) protocol | `references/session-protocol.md` |
| Verify | "Is this actually done?" | Evidence-gated completion: static → runtime → end-to-end, the maker never grades its own work | `references/verification.md` |
| Loop | "Make it run without me" | Goal + verification + stopping condition, maker/checker split, scheduled or event-driven runs | `references/loop-engineering.md` |
| Lifecycle (opt-in) | "Take this feature from idea to shipped" | Staged, gated flow: brainstorm → spec → design → implementation → QA & review, driven by `scripts/feature.py` | `references/feature-lifecycle.md` |

## The Five Subsystems

Every reliable harness has all five; a missing one is the first thing to fix.

| Subsystem | Artifact | Answers |
|---|---|---|
| Instructions | `AGENTS.md` / `CLAUDE.md` (router, 50–200 lines) + topic docs | What is this project? What are the hard rules? |
| Tools | Documented commands, scoped permissions | What can I run? |
| Environment | `init.sh`, lockfiles, pinned versions | How do I get to a working baseline? |
| State | `PROGRESS.md`, `feature_list.json`, git checkpoints | What is done, in progress, blocked, next? |
| Feedback | Explicit verification commands, definition of done | How do I know it worked? |

Feedback is the highest-ROI subsystem when everything is weak — get verification commands
explicit and runnable before anything else. Full rationale, failure taxonomy, and metrics are in
`references/principles.md`.

## Feature Development Lifecycle (opt-in)

For features big enough that "start coding from a one-line title" causes rework, the skill offers
a staged lifecycle — **brainstorm & analyze → requirement spec → technical design →
implementation → QA & code review** — where every stage has a named artifact and a
machine-checked exit gate:

| Stage | Status | Artifact | Exit gate |
|---|---|---|---|
| Brainstorm & analyze | `proposed` | `docs/features/<id>/brief.md` | doc complete (no placeholders) |
| Requirement spec | `in_spec` | `spec.md` | doc complete + executable verification recorded on the entry |
| Technical design | `in_design` | `design.md` | doc complete; monorepo: `affects` filled (change-scope triage) |
| Implementation | `in_progress` | code + evidence | `feature.py verify` ran the commands and they PASS (WIP=1 enforced on entry) |
| QA & code review | `in_qa` | `review.md` | an **independent** checker's `Verdict: Accept` (maker ≠ checker) |

Driven by `scripts/feature.py` (Python 3, stdlib only):

```bash
python3 <skill-dir>/scripts/feature.py init --lifecycle      # or enable rules.lifecycle in feature_list.json
python3 <skill-dir>/scripts/feature.py new "Add item to cart" --area cart
python3 <skill-dir>/scripts/feature.py advance cart-001      # gated stage transitions (WHAT/WHY/FIX on failure)
python3 <skill-dir>/scripts/feature.py verify cart-001       # runs verification, records evidence
python3 <skill-dir>/scripts/feature.py pass cart-001         # final gate -> passing
```

**Stage skills.** Each stage ships as its own skill with a defined role, process, quality bar,
and anti-patterns, plus a dispatcher that routes a feature to wherever it stands:

| Skill | Role | Owns |
|---|---|---|
| `/feature` | lifecycle dispatcher | finds the stage, routes, enforces handoffs (incl. maker ≠ checker at QA) |
| `/feature-brainstorm` | product analyst | problem-first options, recorded rationale, tier call → `brief.md` |
| `/feature-spec` | requirements engineer | falsifiable ACs, explicit out-of-scope, executable verification → `spec.md` |
| `/feature-design` | software architect | smallest design, change-scope triage, contracts + e2e checks, step plan → `design.md` |
| `/feature-implement` | disciplined implementer | WIP=1, per-step verification-green commits, recorded deviations → code + evidence |
| `/feature-review` | independent checker | re-runs everything, cites evidence, issues the verdict — never the implementer → `review.md` |

Three properties keep this honest:

- **Strictly opt-in.** Lifecycle off (the default) = the classic
  `not_started → in_progress → passing` flow everywhere; nothing in the core harness depends on
  this layer, and the audit only scores it for projects that adopted it.
- **Tiered.** Per-feature `full` vs `light` tier — small features skip the stage docs entirely.
  Ceremony scales with feature size, not policy.
- **Tool-optional.** `feature.py` only edits `feature_list.json` and markdown files; any agent or
  human can perform the same transitions by hand, honoring the same gates. The files are the
  interface. The stage list is stored as data (`rules.lifecycle.stages`) so custom lifecycles can
  be added later without a format change.

Full rules: `references/feature-lifecycle.md`.

## Monorepos

When the target repo has workspace markers (`pnpm-workspace.yaml`, `turbo.json`, `nx.json`,
`lerna.json`, `go.work`, Cargo `[workspace]`, multiple deployable apps under `apps/`, …) the skill
applies **two-level rules** from `references/monorepo.md` — every subsystem exists at the root
level *and* the application level:

- Root entry file stays a router (repo map, cross-cutting rules, change-scope triage); every
  deployable app gets its own nested entry file (`AGENTS.app.md` template) with app-specific
  architecture, commands, contracts, and definition of done. New per-app detail goes in the nested
  file, never the root — a root file ballooning with app internals is the #1 monorepo anti-pattern.
- The definition-of-done gate is always the root fan-out command (`turbo run test`, `pnpm -r test`,
  …), never one app's filtered command (`pnpm --filter web test`) — filtered commands are for
  iteration speed only.
- One root progress log and one feature tracker (never per-app competing trackers); every feature
  carries an `affects` scope produced by change-scope triage before code is written.
- Cross-app contract changes (an HTTP shape, an event schema, a shared package's public API) must
  update both sides and be verified end-to-end — this is the failure mode static checks are
  structurally blind to, since duplicated types compile clean on both sides while the system is
  broken at runtime.
- `harness-audit.sh` auto-detects the workspace markers and adds a scored Monorepo section (nested
  entry coverage, triage docs, boundary enforcement). The fresh-session test is scored **per app**
  — harness quality is the minimum across apps, not the average, because the weakest app is where
  the next failure happens.

## Design Principles

- **Repository files are the only interface.** Nothing depends on a specific agent's hooks, MCP
  servers, or memory; any agent that can read files can follow the harness. If it's not in the
  repo, it does not exist for the next session or a different agent.
- **The skill ships generic.** Project-specific bindings (entry file name, verify command, app
  list) are recorded in the target repository, never inside the skill. If you find project facts
  in the skill files, that is contamination — remove them and relocate anything still true into
  the project's own files.
- **Entry files are routers, not encyclopedias.** 50–200 lines; details live in linked topic docs.
  Hard constraints go at the top or bottom, never the middle (lost-in-the-middle degrades
  compliance on rules buried in long text).
- **Done = evidence, not confidence.** A feature is `passing` only when its verification command
  actually ran and the result is recorded; the maker never grades its own work.
- **WIP = 1.** One feature active at a time; the next unlocks only after the current one passes
  verification.
- **Smallest artifact that fixes the observed failure.** Map a failure to a subsystem and fix that
  subsystem — don't answer every failure by growing the entry file.
- **Periodically simplify.** Each harness component encodes an assumption about what models can't
  do; re-test those assumptions as models improve and remove components that no longer earn their
  cost.

## Requirements

- `install.sh` and `scripts/harness-audit.sh`: POSIX-ish `bash` 3.2+ and coreutils only — no other
  dependencies, no network access, both are read-only or write only within the target repo's chosen
  skill directory.
- No runtime dependency on any specific agent. Claude Code and Codex read `SKILL.md` natively;
  everything else consumes the scaffolded repository files directly.

## Updating / Uninstalling

```bash
./install.sh /path/to/your-repo --force            # refresh installed copies in place
./install.sh /path/to/your-repo --only harness     # install/refresh a single skill from the family
rm -rf /path/to/your-repo/.claude/skills/harness   # uninstall one skill (or the .codex/.agents equivalent)
```

The skill writes nothing outside the chosen skill directory; uninstalling never touches the
scaffolded harness artifacts (`AGENTS.md`, `PROGRESS.md`, `feature_list.json`, …) it previously
helped create in the target repo — those are the target repo's own files now.

## Extending the Skill

This repo is itself meant to be edited over time as the methodology or agent ecosystem evolves:

1. **New reference material** → add a file under `skills/harness/references/`, link it from the
   relevant mode in `SKILL.md`, and keep it self-contained (readable without the others loaded).
2. **New template** → add it to `skills/harness/assets/templates/`, use `{{placeholder}}` markers,
   and reference it from the mode or reference file that produces it.
3. **New mechanical check** → extend `scripts/harness-audit.sh`; keep it read-only, bash 3.2+
   compatible, and update the matching checklist in `references/audit.md` so the script and the
   manual rubric never drift apart.
4. **New agent target** → add a flag to `install.sh` following the existing `--claude` / `--codex`
   / `--generic` pattern (a destination directory relative to the target repo).

Keep everything agent-agnostic and project-agnostic; project-specific facts belong in whatever
repo the skill is installed into, never here.

## FAQ

**Does this require Claude Code or Codex?**
No. Those two read `SKILL.md` natively (`/harness`, `$harness`), but the actual value — the
scaffolded `AGENTS.md`, `feature_list.json`, `PROGRESS.md`, `init.sh` — are plain files any agent
(or human) can read and follow. For agents without skill support, point their rules file at
`AGENTS.md`.

**Will it overwrite my existing `AGENTS.md` / `CLAUDE.md`?**
No — scaffold mode inspects what already exists first and never overwrites without explicit
approval; it extends or adds a nested file instead.

**How is a monorepo detected?**
By workspace markers (`pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `lerna.json`, `rush.json`,
`go.work`, `[workspace]` in `Cargo.toml`, `workspaces` in `package.json`) or multiple deployable
apps under `apps/`/`services/`. See `references/monorepo.md` for the full detection list and rules.

**What if the audit score looks low but the repo works fine day to day?**
The lowest subsystem score is a *candidate* bottleneck, not a verdict — confirm it against actual
agent failure history before investing effort. See "How to run an audit" in `references/audit.md`.

## Credits

The methodology this skill operationalizes is drawn primarily from the
**[Learn Harness Engineering](https://walkinglabs.github.io/learn-harness-engineering/en/) course**
— the five subsystems, the failure taxonomy, WIP=1, feature lists as harness primitives, clean
state, and the maker/checker split are its core teachings. This project packages that curriculum
into repository-native artifacts and a companion feature-lifecycle skill family, but the
methodology and the credit for it are the course's.

Additional influences: OpenAI's Codex harness-engineering practices, Anthropic's research on
harnesses for long-running agents, and Addy Osmani's writing on Loop Engineering.
