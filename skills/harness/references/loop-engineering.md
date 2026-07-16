# Loop Engineering

Harness engineering makes a single run reliable; loop engineering makes continuous runs autonomous.
"Replace yourself as the person who prompts the agent — design the system that does it instead"
(Osmani). Use this when the user wants recurring, scheduled, goal-driven, or unattended agent work.

Prerequisites: loops only work on top of a solid harness. If sessions don't leave clean state
(session-protocol.md) or completion isn't evidence-gated (verification.md), fix that first — a loop
amplifies whatever discipline (or chaos) already exists.

## The Minimal Loop: goal + verification + stopping condition

Every loop reduces to three parts:

- **Goal**: the end state, not the next step ("all tests pass, zero lint warnings, merged").
- **Verification**: a machine-checkable way to measure progress toward it.
- **Stopping condition**: decided by an *independent* judge (script, test command, separate
  evaluator session) — never by the agent doing the work. Agents declare victory too easily.

## Choosing the Loop Type

One-sentence test: **does the work have an end?**

| Type | Trigger | Stops when | Use for |
|---|---|---|---|
| Turn-based | Human types each prompt | Human satisfied | Small/exploratory tasks |
| Goal-based (`/goal`-style) | One goal given | Independent evaluator confirms done / budget out | Complex tasks with a clear finish line |
| Time-based (`/loop`, cron, scheduled tasks) | Interval | Manually stopped | Polling, periodic checks; each run independent |
| Event-driven | External event (PR opened, CI failed, webhook) | Event handled | CI/CD and tracker integration |

Common mistake: putting goal-shaped work in a timer loop ("every 10m: keep implementing the payment
system"). Timer runs don't accumulate progress unless state is persisted — you get the same
starting point repeatedly.

## The Six Primitives

Compose loops from these; not all are needed every time:

1. **Automations** — the heartbeat: in-session repeaters, OS cron, scheduled tasks, cloud routines,
   CI triggers, webhooks. Without a trigger, a loop is a blueprint that never wakes up.
2. **Worktrees** — isolation: each parallel agent gets its own git worktree/branch; file collisions
   become physically impossible. Human review bandwidth remains the true parallelism ceiling.
3. **Skills** — codified project knowledge (like this one): conventions and procedures written once,
   read every run, instead of re-explained per session.
4. **Connectors** (MCP or equivalent) — reach into real tools: issue tracker, database, staging API,
   chat. The difference between "here's a fix" and "PR opened, ticket linked, channel notified."
5. **Sub-agents** — the maker/checker split: explorer → implementer → verifier. The verifier uses a
   different prompt (sometimes a different model) and must cite evidence for its verdict.
6. **External state** — the loop's memory: a markdown/JSON file (or issue board) on disk recording
   what's done / in progress / next. Models forget between runs; the repository doesn't. This is
   the spine of every loop — `PROGRESS.md` and `feature_list.json` are the natural substrate.

## Reference Anatomy: a self-feeding loop

```
Trigger (cron/event)
  → Read external state (PROGRESS.md, feature list, open issues)
  → Pick next actionable item (WIP=1 per worker)
  → Fork isolated worktree
  → Implementer sub-agent: fix + tests
  → Verifier sub-agent: independent tests + lint + review  ──fail──▶ retry queue
  → Pass: open PR / commit, update external state
  → Work remains? loop : land results in a review inbox for the human
```

The human's job shifts to: define goal and stopping condition up front, review the inbox, and
refine rules/skills when the system misbehaves.

A proven pattern for experimental/optimization work is the **ratchet loop**: propose change →
snapshot (commit) → run fixed-budget evaluation → improved? keep : revert → log result → repeat.
Give the agent a *methodology document* (what to explore, what not to touch, how to evaluate,
what to do on failure) rather than a task list, and let the methodology be the loop.

## The Four Silent Costs

Audit these regularly; they grow with loop runtime:

1. **Verification debt** — fast loops tempt "looks fine". Stopping conditions must be
   machine-checkable, never vibes.
2. **Comprehension rot** — the faster the loop ships, the further your understanding drifts from
   the codebase. Fast loops require fast *reading*; schedule it.
3. **Cognitive surrender** — accepting output without opinions. The loop should amplify thinking
   about work you understand, not replace understanding.
4. **Token blowout** — context grows superlinearly with turns. Manage from the first loop:
   compaction, session resets from external state, per-run fresh contexts.

## Maturity Ladder

Climb one rung at a time; most teams sit at 2–3:

1. **Goal runner** — one goal + stopping condition, agent loops until met.
2. **Scheduled single task** — one automation, one recurring job (e.g. morning CI triage).
3. **Multi-agent loop** — maker/checker split, isolated worktrees per item.
4. **Self-feeding loop** — discovers its next task from external state.
5. **Fleet** — multiple parallel loops sharing a memory layer.

## Building the First Loop (checklist)

1. Pick one task done manually ≥2×/week (issue triage, pre-review lint+test, EOD progress update).
2. Write goal, verification, stopping condition in a markdown block.
3. Split maker and checker prompts; checker must cite evidence.
4. Add memory: a state file read at start, updated at end of every run.
5. Schedule it (in-session repeater → OS cron → cloud routine, lightest that works). Start daily;
   observe a week before increasing frequency or scope.

## Tool Mapping (non-normative)

The primitives are tool-agnostic; concrete bindings, wherever available in the environment:
Claude Code — `/loop` (in-session), scheduled tasks / cloud routines, `Agent`/sub-agents,
`isolation: worktree`, skills, MCP connectors, hooks. Codex — thread automations, standalone
automations + Triage inbox, `codex exec` + cron, sub-agents, `$skill`, MCP. Anything else —
CI schedules (GitHub Actions cron), webhooks, plain cron + CLI runs. Always keep the loop's state
and rules in repository files so switching tools doesn't break the loop.
