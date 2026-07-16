---
name: feature
description: >-
  Orchestrate the feature development lifecycle: find where a feature stands (brainstorm & analyze
  → requirement spec → technical design → implementation → QA & code review), route to the right
  stage skill, and drive gated stage transitions with scripts/feature.py. Use when: (1) the user
  says "work on feature X", "continue the cart feature", "what's next for <id>", (2) starting a
  new feature idea end-to-end, (3) the user asks which stage a feature is in or what remains,
  (4) managing feature_list.json states (advance, verify, block, pass). Companion to the harness
  skill; stage-specific guidance lives in the feature-brainstorm, feature-spec, feature-design,
  feature-implement, and feature-review skills.
---

# Feature Lifecycle Orchestrator

You are the **lifecycle dispatcher**: your job is not to do stage work yourself, but to put the
feature in front of the right stage discipline, with its gates intact. The rules of the lifecycle
(stages, artifacts, gates, tiers) are defined in
[../harness/references/feature-lifecycle.md](../harness/references/feature-lifecycle.md) — this
skill assumes the harness skill is installed alongside.

## Routing procedure

1. **Locate state.** Read `feature_list.json` at the repo root. No file → offer to set up via the
   harness skill (`feature.py init [--lifecycle]`). If the user named no feature, run
   `python3 <skill-dir>/../harness/scripts/feature.py list` (or read the JSON) and either pick the
   obvious in-flight item or ask which one.
2. **New idea?** Create it first: `feature.py new "<title>" --area <x> [--tier light]`, then route
   to `proposed`. Tier call: single-component, ~one-session change → `light`; crosses
   components/apps, changes contracts, or needs multi-session work → `full`.
3. **Route by status.** Read the matching stage skill and follow it:

| Status | Stage | Read and follow |
|---|---|---|
| `proposed` | Brainstorm & analyze | [../feature-brainstorm/SKILL.md](../feature-brainstorm/SKILL.md) |
| `in_spec` | Requirement spec | [../feature-spec/SKILL.md](../feature-spec/SKILL.md) |
| `in_design` | Technical design | [../feature-design/SKILL.md](../feature-design/SKILL.md) |
| `in_progress` / `not_started` | Implementation | [../feature-implement/SKILL.md](../feature-implement/SKILL.md) |
| `in_qa` | QA & code review | [../feature-review/SKILL.md](../feature-review/SKILL.md) |
| `blocked` | — | surface the blocker from `notes`; resolve or escalate, then `feature.py unblock` |
| `passing` | done | nothing to do; suggest the next feature by priority |

4. **Advance only through the tool** (`feature.py advance <id>`) or by honoring the identical
   gates manually — never by editing `status` to skip a gate. A gate failure prints WHAT/WHY/FIX;
   fix the named artifact, don't argue with the gate. Backward is different: rework goes to an
   earlier stage via `feature.py regress <id> [<stage>]` (ungated by design), and external
   blockers via `block`/`unblock`.

## Hard rules you enforce as dispatcher

- **One stage at a time, one feature in implementation.** WIP=1 applies to `in_progress`;
  upstream doc stages may pipeline in parallel with another feature's implementation.
- **Maker ≠ checker at QA.** If this same session (or agent context) implemented the feature, do
  NOT route yourself into feature-review — hand off to a fresh session, a sub-agent with a clean
  context, or a human. Say so explicitly.
- **Stage docs are the memory.** Each stage reads its predecessors' artifacts
  (`docs/features/<id>/brief.md → spec.md → design.md`) — never re-derive from chat history what
  a previous stage already wrote down.
- **Tier honestly.** If mid-lifecycle a full-tier feature turns out trivial, demote to light
  (record why in `notes`) instead of writing ceremony docs after the fact.
- **Lifecycle off?** The stage skills still work as pure practice guides (spec thinking, design
  review, independent QA) — apply them to the classic
  `not_started → in_progress → passing` flow without stage docs or gates.

## Typical dispatch, end to end

```bash
python3 <skill>/../harness/scripts/feature.py new "Add item to cart" --area cart
# → proposed        : follow feature-brainstorm  → brief.md complete   → advance
# → in_spec         : follow feature-spec        → spec.md + verification → advance
# → in_design       : follow feature-design      → design.md (+ affects)  → advance
# → in_progress     : follow feature-implement   → code, verify PASS      → advance
# → in_qa           : HAND OFF to fresh session  → feature-review → Verdict: Accept → pass
```

At every hop, report to the user: current stage, what the exit gate needs, and who does it.
