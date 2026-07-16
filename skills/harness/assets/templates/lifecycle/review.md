# QA & Code Review: {{title}}

Feature: `{{id}}` · Stage: **QA & code review** · Reviewed: {{date}}

<!-- Filled by an INDEPENDENT checker — a fresh session, an evaluator agent, or a human —
     NEVER the session that wrote the code (maker ≠ checker). Score with evidence, not vibes;
     dimensions follow evaluator-rubric.md. Exit gate: the literal line "Verdict: Accept". -->

## Verification Re-Run

<!-- The checker re-runs the feature's verification commands themselves (do not trust the
     implementer's recorded run). Cite actual output. -->

- Commands run: {{...}}
- Result: {{PASS / FAIL + key output}}

## Acceptance Criteria Check

<!-- One row per AC from spec.md. Light-tier features: check against user_visible_behavior. -->

| Criterion | Pass? | Evidence |
|---|---|---|
| {{AC1}} | {{yes/no}} | {{output, screenshot ref, commit}} |

## Code Review Findings

### Blocking
- {{finding that must be fixed before Accept — or "none"}}

### Non-Blocking
- {{improvement worth a follow-up feature/task — or "none"}}
- {{recurring category of mistake? promote to a lint rule/test per review-feedback promotion}}

## Scope & Clean-State Check

- Stayed inside the feature's scope (spec's Out of Scope respected): {{yes/no}}
- No stale artifacts (debug logs, commented-out code, temp files): {{yes/no}}
- Progress log + feature entry reflect reality: {{yes/no}}

## Verdict

<!-- Exactly one of: Accept / Revise / Block, on its own line, prefixed "Verdict: ".
     Accept requires: verification re-run PASS, all ACs pass, no blocking findings. -->

Verdict: {{Accept | Revise | Block}}

## Required Follow-Ups

- {{fixes required for Revise, or follow-up items spun off after Accept — or "none"}}
