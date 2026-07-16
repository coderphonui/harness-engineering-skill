# Harness Engineering Principles

Distilled from OpenAI's "Harness engineering" (Codex agent-first practices), Anthropic's
"Effective harnesses for long-running agents" and "Harness design for long-running application
development", Addy Osmani's "Loop Engineering", and the learn-harness-engineering course
(13 lectures). Use this file when designing a harness or explaining a harness decision.

## Contents

1. [Why capable models still fail](#1-why-capable-models-still-fail)
2. [The repository as system of record](#2-the-repository-as-system-of-record)
3. [Instruction architecture: split, don't grow](#3-instruction-architecture-split-dont-grow)
4. [State persistence across sessions](#4-state-persistence-across-sessions)
5. [Initialization is its own phase](#5-initialization-is-its-own-phase)
6. [Scope control: WIP=1](#6-scope-control-wip1)
7. [Feature lists are harness primitives](#7-feature-lists-are-harness-primitives)
8. [Observability](#8-observability)
9. [Entropy and clean state](#9-entropy-and-clean-state)
10. [Harness simplification](#10-harness-simplification)
11. [Key metrics](#11-key-metrics)

---

## 1. Why capable models still fail

Model capability and execution reliability are different things. The same model in a bare repo vs.
a harnessed repo produces qualitatively different results (Anthropic's controlled experiment: same
prompt, same Opus model — bare run produced a broken app; planner/generator/evaluator harness
produced a fully working one).

The five recurring failure modes, each mapping to one subsystem:

1. **Vague requirements** → the agent guesses → task-specification fix (definition of done).
2. **Implicit conventions not written down** → the agent cannot comply → instructions fix.
3. **Incomplete environment** → context burned on setup errors → environment fix (`init.sh`).
4. **No verification methods** → "feels done" replaces "is done" → feedback fix.
5. **Cross-session state loss** → every session starts from scratch → state fix.

**Diagnostic loop**: execute → observe failure → attribute to one of the five subsystems → fix that
subsystem → re-execute. Keep a simple log of failures and their attributed layer; after a few
rounds the bottleneck subsystem is obvious. "The model isn't good enough" is not an attribution.

**Definition of Done**: every task gets completion criteria verifiable by command, e.g.:

```
Completion criteria:
- New endpoint GET /api/search?q=xxx
- Pagination, default 20 items
- All new code passes the test suite
- Type check and lint pass
```

## 2. The repository as system of record

An agent has exactly three inputs: the prompt, repository files, and tool output. Slack, Jira,
Confluence, and heads-of-engineers do not exist for it. Therefore:

- **Knowledge lives next to code.** A 50-line `ARCHITECTURE.md` inside the module beats a 500-page
  wiki. Proximity beats length — when the agent reaches the code it also reaches the constraints.
- **Fresh session test** — a brand-new session, given only the repo, must be able to answer:
  What is this system? How is it organized? How do I run it? How do I verify it? Where are we now?
  Every unanswerable question is a blank spot on the map where the agent will guess.
- **Minimal but complete.** Every rule must have a use case; every fresh-session question must
  have an answer. Stale docs are worse than no docs — they send the agent confidently in the wrong
  direction. Bind doc updates to code changes.
- **ACID for agent state**: Atomicity — one logical operation per commit, roll back cleanly.
  Consistency — a verifiable "consistent state" predicate (all checks pass) after each operation.
  Isolation — concurrent agents get separate branches/worktrees/progress files. Durability —
  cross-session knowledge lives in git-tracked files, never only in the conversation.

## 3. Instruction architecture: split, don't grow

The vicious cycle: agent errs → "add a rule" → entry file balloons → performance degrades. Why:

- **Context budget**: a 600-line entry file eats 10–20K tokens before any code is read.
- **Lost in the middle**: LLMs use information at the start and end of long text far better than
  the middle (Liu et al. 2023). A security constraint at line 300 of 600 will be ignored.
- **No priority signal**: hard constraints, style preferences, and historical anecdotes all look
  identical, so the agent cannot tell red lines from suggestions.
- **Contradiction accumulation**: rules added at different times conflict; the agent picks randomly.

Fix: the entry file is a **router** — 50–200 lines containing project overview, first-run commands,
≤15 global hard constraints, and links to topic docs ("`docs/api-patterns.md` — required when
adding endpoints"). Topic docs are 50–150 lines each, loaded on demand, ideally co-located with
their module. Every instruction should have a source (why added), applicability condition (when
needed), and expiry condition (when removable). Audit and delete like you manage dependencies.

## 4. State persistence across sessions

Context windows are finite; long tasks will span sessions. What gets lost is disproportionately
the **why** (rejected alternatives, decision rationale) rather than the **what** (the code) — so a
new session may "optimize away" a deliberate decision.

Treat the agent as an engineer whose short-term memory is wiped every shift. Before clocking out
it writes down; on clocking in it reads:

- **PROGRESS.md** — current verified state (commit, test status), done / in-progress / blocked,
  known issues, next steps.
- **Decision log** (in PROGRESS.md or DECISIONS.md) — what was decided, why, what was rejected.
- **Git checkpoints** — commit after each atomic unit; messages explain what and why.
- **Handoff note** — for long sessions: what's verified, what changed, what's broken, next best
  action, commands.

**Context anxiety**: when nearing the context limit, agents rush — skipping verification, choosing
the easy path. Counter with structured handoff + reset (a fresh session rebuilding from artifacts)
rather than pushing a dying session to finish. Rule of thumb: if a task needs >60% of the window,
start preparing the handoff. Target rebuild cost for a new session: under ~3 minutes.

## 5. Initialization is its own phase

Initialization (environment, test framework, task breakdown) and implementation (features) have
different optimization targets; mixed together, agents favor visible feature code and skimp on
infrastructure, whose absence only hurts in the *next* session.

A dedicated initializer session produces: runnable environment; at least one passing example test;
a startup-readiness doc (start/test/verify commands, structure); an ordered task breakdown with
acceptance criteria; and a clean baseline commit. Acceptance = four conditions: **can start, can
test, can see progress, can pick up next steps.** Start from a template, not an empty directory.
The upfront time is repaid within 3–4 sessions.

## 6. Scope control: WIP=1

Agents naturally overreach ("while I'm here…") because generating the next idea is nearly free,
but every parallel task divides attention. Overreach and under-finish amplify each other: diluted
attention leaves half-finished code, which raises complexity, which invites more overreach.
Empirically, lines of code written correlates *negatively* with features completed.

- Only one feature in `active` status at any time.
- The next feature unlocks only when the current one passes end-to-end verification.
- Completion evidence must be executable ("this command returns 201"), not aesthetic ("looks fine").
- Track Verified Completion Rate = verified / activated; block new activations while VCR < 1.

## 7. Feature lists are harness primitives

A feature list is not a memo — it is the data structure the scheduler (pick next task), verifier
(gate state transitions), handoff reporter, and progress tracker all read. Documents can be
ignored; primitives cannot be bypassed.

Each entry is a triple + evidence:

```json
{
  "id": "F03",
  "behavior": "POST /cart/items with {product_id, quantity} returns 201",
  "verification": "curl -X POST .../api/cart/items -d '...' | jq .status == 201",
  "status": "passing",
  "evidence": "commit abc123, test output"
}
```

- States: `not_started → in_progress → (blocked |) passing`. Passing requires the verification to
  actually run; the transition is earned, not asserted.
- Granularity: completable in one session. "User can add items to cart" — right. "Implement the
  shopping cart" — too broad. "Add name field to Cart model" — too narrow.
- Single source of truth: scope info in conversations or TODO comments that contradicts the list
  is a bug; reconcile into the list.

## 8. Observability

Without observability, decisions are guesses, evaluation is mysticism, and retries are blind.
Two layers, both required:

- **Runtime observability** — what the system did: logs, traces, startup/ready state, critical-path
  execution, side effects, resource anomalies. Built into the harness (scripts/checks), not left to
  the agent's discretion — agents don't log what they don't know they'll need.
- **Process observability** — why a change should be accepted: sprint contracts (scope,
  verification standards, exclusions agreed *before* coding) and evaluator rubrics (dimension ×
  grade tables with hard thresholds), so different evaluators reach the same verdict with cited
  evidence ("contrast 2.1:1, standard requires 4.5:1"), not "doesn't feel right".

Evaluators need tuning: out of the box they identify issues then talk themselves into approving.
Compare their verdicts with human judgment, tighten the rubric where they diverge, repeat 3–5
rounds.

## 9. Entropy and clean state

Entropy growth is the default: agents copy existing patterns, including bad ones, so every messy
session compounds (measured decay over 12 weeks without cleanup: build pass rate 100%→68%, session
startup 5→60+ min; with cleanup: 97% and 9 min).

- **Clean state = five conditions** at session end: build passes, tests pass, progress recorded,
  no stale artifacts (debug logs, commented-out code, temp files), standard startup path works.
  Session completion = task verified AND clean state. "Clean up later" means never.
- **Dual-mode cleanup**: immediate (every session end) + periodic (weekly sweep: structural issues,
  quality-document update, drift detection). Cleanup scripts must be idempotent.
- **Golden rules encoded in the repo**: e.g. "prefer the shared utility over hand-rolled helpers",
  "don't guess data structures — validate at boundaries". Concrete, mechanical, checkable.
- **Quality document**: an A–D grade per product domain and architectural layer (verification,
  agent legibility, test stability, boundary compliance). Answers "is the codebase getting
  stronger or weaker?" — the rubric grades sessions, the quality document grades the repo.
- **Review-feedback promotion**: recurring review comments become lint rules or tests. Captured
  human taste is enforced forever; the harness strengthens automatically.

## 10. Harness simplification

Every harness component encodes an assumption about what the model cannot do. Models improve;
assumptions go stale; stale components become overhead (Anthropic removed their sprint-splitting
mechanism when a newer model handled decomposition natively — the harness got *better*; but their
independent evaluator kept earning its place). Practice: periodically disable one component, run
benchmark tasks, compare. No degradation → remove; degradation → restore or lighten. The valuable
combinations don't shrink as models improve — they shift.

## 11. Key metrics

| Metric | Definition | Healthy target |
|---|---|---|
| Rebuild cost | Time for a new session to reach an executable state | < 3 min |
| Verified Completion Rate | verified tasks / activated tasks | 1.0 before new activations |
| Verification gap | claims of done that were not actually done | trending to 0 |
| Fresh-session test | of the 5 orientation questions, how many answerable from repo alone | 5/5 |
| Knowledge visibility gap | share of critical project knowledge not in the repo | < 10% |
| Clean-state pass rate | sessions ending with all 5 clean-state conditions | ~100% |
