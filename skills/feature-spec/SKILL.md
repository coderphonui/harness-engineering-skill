---
name: feature-spec
description: >-
  Run the requirement spec stage of the feature lifecycle: turn a brief's chosen direction into
  user-visible behavior, verifiable acceptance criteria, explicit scope boundaries, edge cases,
  and an executable verification plan in spec.md. Use when: (1) a feature is at status `in_spec`,
  (2) the user asks to write requirements, acceptance criteria, or a spec for a feature,
  (3) a feature keeps failing QA because "done" was never defined. Exit gate: spec.md complete
  AND verification commands recorded on the feature entry → advance to in_design.
---

# Feature Requirement Spec

**Your role: requirements engineer.** Define WHAT the system will do, precisely enough that an
independent checker can later verify it without asking anyone. You do not decide HOW (that's
feature-design), and you don't reopen WHY (that's decided in brief.md — read it first; if the
direction seems wrong, go back a stage rather than quietly speccing something else).

Artifact: `docs/features/<id>/spec.md`. Exit gate — the strictest upstream gate in the lifecycle:
spec complete AND the Verification Plan copied into the entry's `"verification"` array in
`feature_list.json`. **A spec is not done until its acceptance criteria are executable.** This
front-loads the definition of done at the cheapest possible moment.

## Process

1. **Read the inputs**: `brief.md` (chosen direction, open questions passed forward), the feature
   entry, and the repo entry file for conventions the behavior must respect (auth model, i18n,
   error format).
2. **Write the user-visible behavior** — one or two sentences a non-engineer could confirm.
   Copy its essence into the entry's `user_visible_behavior`.
3. **Acceptance criteria, each one falsifiable.** The test: could a criterion *fail*? "Works
   well" cannot fail; "POST /cart/items with a valid product returns 201 and the item appears in
   GET /cart" can. Given/When/Then phrasing helps when behavior depends on state. Number them —
   review.md will check them one by one.
4. **Out of scope, explicitly.** Everything adjacent that this feature will NOT do. This section
   is the WIP=1 fence for the implementation stage — every "while I'm here" temptation you can
   name now is a scope drift prevented later.
5. **Edge cases & error behavior.** Walk the standard sweep: empty/missing/malformed input,
   unauthorized access, dependency failure (API down, DB timeout), concurrent use, limits
   (pagination, size, rate). For each relevant one: input/state → expected behavior. "Returns a
   clear error" is not expected behavior; name the status/message shape.
6. **Verification plan → executable.** Commands (or scripted steps) that prove the ACs — then
   copy them into the entry so `feature.py verify` can run them. Prefer commands that exist or
   will exist ("run the new test file X") over hypothetical tooling. If an AC can only be checked
   by a human-driven flow, script as much as possible and state the manual residue precisely —
   the QA stage will drive it.

## Quality bar

- Every AC maps to at least one verification command/step, and vice versa.
- A stranger could implement against this spec without asking a question whose answer changes
  behavior (questions that only affect internals are fine — they're design's job).
- No design leakage: the spec names no modules, libraries, or schemas unless they're genuinely
  part of the user-visible contract.
- Edge cases state *behavior*, not intentions.

## Anti-patterns

- Vague ACs ("fast", "intuitive", "handles errors gracefully") — unfalsifiable, so QA becomes
  vibes and the maker's confidence wins by default.
- `verification` filled with "test manually" to satisfy the gate — the gate exists to make QA
  re-runnable; hollow commands defeat the one mechanism protecting "done = evidence".
- Speccing the solution ("use a Redis sorted set…") — you've started designing; move it to the
  next stage.
- Silently expanding past the brief's direction because more scope "makes sense" — that's a new
  decision; take it back through the user or the brief.
- Skipping Out of Scope because "it's obvious" — it's only obvious until an agent with a full
  context window decides adjacent code "needed" refactoring.

Next stage: [feature-design](../feature-design/SKILL.md). It inherits your ACs as fixed
constraints — anything ambiguous here becomes an invented decision there.
