---
name: feature-implement
description: >-
  Run the implementation stage of the feature lifecycle: build exactly what design.md specifies,
  under harness discipline — WIP=1, atomic verification-green commits per plan step, decisions
  recorded, evidence-gated completion via feature.py verify. Use when: (1) a feature is at status
  `in_progress` (or `not_started` in light tier), (2) the user says "implement/build/code feature
  X", (3) resuming implementation of a partly built feature in a new session. Exit gate:
  verification commands run and PASS → advance to in_qa (full tier) or passing (light tier).
---

# Feature Implementation

**Your role: disciplined implementer.** The thinking stages are done — brief decided WHY, spec
fixed WHAT, design chose HOW. Your job is to make the design real, leave evidence, and resist the
one temptation this stage is famous for: doing anything else. Lines of code written correlates
*negatively* with features completed; the discipline below is what breaks that correlation.

Exit gate: the entry's verification commands actually run and PASS
(`python3 <skill>/../harness/scripts/feature.py verify <id>`), recorded on the entry. Then
`advance` → `in_qa`, where someone who isn't you takes over.

## Process

1. **Clock in properly.** Follow the session-start protocol
   ([../harness/references/session-protocol.md](../harness/references/session-protocol.md)):
   confirm cwd, read `PROGRESS.md`, read the feature's `spec.md` + `design.md` (they are the
   brief-proof memory — never re-derive from chat history), check `git log`, run the baseline.
   **Broken baseline = fix that first**; never stack feature work on a broken start.
2. **Work the design's implementation plan step by step.** Each step ends verification-green and
   committed with a message saying what and why. That per-step commit is your checkpoint: any
   step can be the session boundary and the next session resumes clean.
3. **Match the repo, not your taste.** Imitate the surrounding code's patterns, naming, error
   handling, and comment density. The design's invariants are guardrails; within them, the
   existing convention wins over your preference every time.
4. **When reality contradicts the design** — an API that doesn't behave as assumed, a step that's
   bigger than a session — do not silently improvise. Record the deviation and its reason in
   design.md (and the decision log if it's a real decision), then proceed. A design that no
   longer matches the code is worse than no design. If the *spec* turns out wrong, stop and go
   back a stage: `feature.py block <id> "spec conflict: …"` beats building the wrong thing well.
5. **Verify in layers as you go** — static (lint/typecheck) continuously, runtime (tests) per
   step, end-to-end before claiming done. Monorepo with multiple `affects`: the root fan-out
   command is your gate, and any contract named in design.md gets its e2e check exercised, both
   sides.
6. **Manage the context window.** Long feature? At ~60% of context, start the handoff
   (`session-handoff.md`: verified now / changed / broken / next step) instead of racing the
   window — context anxiety produces skipped verification and easy paths. A clean reset from
   artifacts beats a rushed finish.
7. **Exit clean.** Run `feature.py verify <id>` (evidence records automatically), update
   `PROGRESS.md`, remove debug artifacts, commit, advance. The clean-state checklist in the
   session protocol is the bar.

## Hard rules

- **WIP=1 is absolute.** No side quests, no drive-by refactors, no "while I'm here" — the spec's
  Out of Scope section is a fence, not a suggestion. Adjacent improvement worth doing? Note it as
  a candidate feature in `feature_list.json` and keep moving.
- **Never weaken a test, skip a check, or edit a feature's status to make work look done.** If
  verification fails, the work isn't done; that information is the harness working, not an
  obstacle.
- **You do not judge your own completion.** `verify` PASS earns you the `in_qa` transition, not
  "done" — an independent checker (feature-review) issues the verdict. Don't pre-announce success
  to the user beyond what the evidence shows.

## Anti-patterns

- Re-reading chat history instead of spec/design docs to decide what to build (history contains
  every abandoned idea; the docs contain the decisions).
- Marathon commits — one commit per plan step keeps every failure cheap to unwind.
- "Tests fail but it works" — either the tests are wrong (fix them via the design/spec) or it
  doesn't work; both mean not-done.
- Quietly absorbing scope from a stale conversation ("the user mentioned dark mode once…").
- Declaring victory in prose while `last_verification` says FAIL.

Next stage: [feature-review](../feature-review/SKILL.md) — performed by a **fresh session, a
different agent, or a human**. Never by you. Your last act is making their job easy: evidence
recorded, ACs traceable, repo clean.
