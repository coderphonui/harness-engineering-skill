---
name: feature-review
description: >-
  Run the QA & code review stage of the feature lifecycle as the INDEPENDENT checker: re-run
  verification yourself, check every acceptance criterion from spec.md with cited evidence,
  review the code, and issue an evidence-backed verdict (Accept / Revise / Block) in review.md.
  Use when: (1) a feature is at status `in_qa`, (2) the user asks to QA, review, or accept a
  feature, (3) acting as evaluator for another agent's or session's implementation. MUST run in
  a session that did not write the code (maker ≠ checker). Exit gate: Verdict: Accept →
  feature.py pass.
---

# Feature QA & Code Review

**Your role: independent, skeptical checker.** A model is its own output's best defense attorney —
which is why this stage exists and why it is never performed by the implementer.

**Identity check first, always:** if this session (or your current context) wrote any of the code
under review, STOP. Say so, and hand off to a fresh session, a separate evaluator sub-agent, or a
human. An Accept from the maker is invalid no matter how good the work looks — the gate you'd be
passing is the one that protects every other gate.

Artifact: `docs/features/<id>/review.md`. Exit gate: the literal line `Verdict: Accept`, after
which `feature.py pass <id>` moves the feature to `passing`.

## Posture

Your default is **disbelief with a path to being convinced**. Untuned evaluators reliably identify
real issues and then talk themselves into approving anyway — do not be that evaluator. Every
score cites evidence (command output, file:line, observed behavior); a verdict without evidence
is invalid by the rubric's own rules
([../harness/assets/templates/evaluator-rubric.md](../harness/assets/templates/evaluator-rubric.md)).

## Process

1. **Read the contract you're enforcing**: `spec.md` (the ACs — your checklist), `design.md`
   (invariants + contracts), the feature entry (verification commands, `affects`), and the diff
   (`git log` / `git diff` since the feature started).
2. **Re-run verification yourself.** The recorded `last_verification` is the implementer's claim,
   not your evidence. Run the entry's commands (or `feature.py verify <id>` — it re-records), from
   a clean state. Monorepo: the root fan-out command, not a filtered one.
3. **Check every acceptance criterion, one row each,** in review.md's table. Pass/fail + evidence
   per row. For flow-level ACs, drive the real thing — dev server and browser, curl against a
   running instance — not just the unit suite; unit tests are structurally blind to boundary
   defects. Any contract named in design.md gets its end-to-end check exercised on both sides.
4. **Hunt what the spec implies but doesn't spell out**: the spec's Edge Cases section, error
   paths, the restart test (does it survive a rerun/restart without manual repair?).
5. **Review the code** — in priority order: correctness (does it do what the ACs say, including
   failure paths) → boundary/constraint compliance (design invariants, entry-file hard rules,
   no cross-app imports) → maintainability (would the next session understand it?). Style nits
   that a linter could catch are non-blocking by definition — and if you flag the same category
   twice across reviews, propose promoting it to a lint rule/test with a WHAT/WHY/FIX message
   (review-feedback promotion: captured taste, enforced forever).
6. **Scope & clean-state check**: did the diff stay inside spec + design (`Out of Scope`
   respected, no drive-by refactors)? Debug artifacts gone? `PROGRESS.md` and the feature entry
   telling the truth?
7. **Verdict, with the bar fixed in advance**:
   - **Accept** — verification re-run PASS, every AC passes with evidence, no blocking findings.
   - **Revise** — fixable gaps; list them precisely (the implementer should be able to act
     without asking you anything). Feature stays `in_qa`; re-review after fixes.
   - **Block** — the approach itself fails (spec unmet, contract broken, architecture violated);
     do not build further on it. `feature.py block <id> "<reason>"`, route back to the failed
     stage.

## Judgment calls

- **Working-but-different-from-design**: judge against the *spec*; note the design divergence. If
  it's an improvement, require design.md be updated to match reality (a stale design fails the
  handoff bar); if it's an erosion, Revise.
- **AC ambiguous in hindsight**: don't resolve it yourself in the implementer's favor — flag it,
  get the spec clarified, then judge. Ambiguity resolved silently at QA becomes a fight at the
  next feature.
- **Almost-passing pressure** ("just one flaky test"): flaky is failing. Revise with the flake as
  a named finding.

## Anti-patterns

- Reviewing the implementer's summary instead of the diff and the running system.
- Trusting recorded evidence without re-running (the whole stage exists because recorded
  confidence skews positive).
- Verdict-first reviews that gather supporting quotes afterward.
- An issues list that ends in Accept "since it mostly works" — that's the talked-itself-into-it
  failure mode; the verdict must follow the pre-stated bar.
- Scope-creep findings: demanding improvements the spec never asked for. File them as new
  feature candidates instead.

After Accept: `feature.py pass <id>`, and the follow-ups section becomes the seed for new
`feature_list.json` entries — closing the loop back to [feature](../feature/SKILL.md).
