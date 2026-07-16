# Verification & Definition of Done

How to prevent premature "done" declarations and make completion an objective determination.
Background: models are systematically overconfident (Guo et al. 2017); an agent evaluating its own
work reliably skews positive. Done must be decided by evidence, never by the maker's confidence.

## Definition of Done

Write it per task, verifiable by command:

```
## Definition of Done
- Feature complete = end-to-end verification passed, not "code is written"
- Required levels:
  1. Static: lint + type check pass
  2. Runtime: tests pass, app starts and reaches ready state
  3. System: the complete user flow executes correctly end-to-end
- Do not proceed to a level while the previous one fails
- No refactoring / optimization / style work until core functionality is verified
```

## Three-Layer Termination Check

| Layer | What runs | What it proves |
|---|---|---|
| 1. Static | lint, type check, build | The words are spelled correctly |
| 2. Runtime | unit/integration tests, startup check, critical paths | Not just written — runnable |
| 3. System | end-to-end flow, real user scenario, side-effect checks | Not just runnable — correct |

Layer 3 is mandatory whenever the change crosses component boundaries. Unit tests are
*systematically blind* to boundary defects — their isolation design (mocks) is exactly what hides
interface mismatches, cross-layer state propagation errors, resource lifecycle leaks, and
environment/config differences. In practice, e2e also changes agent behavior: knowing the full
flow will run, the agent writes for integration, respects boundaries, and handles error paths.

Useful runtime signals: app started and reached ready state; critical paths executed; database
writes / file operations / side effects correct; temporary resources cleaned up.

## Maker ≠ Checker

The entity that wrote the code never issues the completion verdict. A model is its own output's
best defense attorney — it doesn't see mistakes, it sees its reasoning. Options, lightest first:

1. **Script gate**: the feature's verification command decides the state transition. The agent
   submits a verification request; the command's exit status is the verdict. (Mechanized by the
   bundled `scripts/feature.py`: `verify` runs the entry's commands and records the result;
   `advance`/`pass` refuse transitions whose gate evidence is missing.)
2. **Independent session**: a fresh context (no memory of writing the code) re-runs verification
   and reviews the diff against the feature's behavior description.
3. **Evaluator agent**: a separate agent — different prompt, tuned to be skeptical, ideally able to
   drive the real app (e.g. browser automation) — scores against a rubric with hard thresholds.

### Evaluator rubric

Score with fixed dimensions and cite evidence, not vibes (template:
`assets/templates/evaluator-rubric.md`): correctness, verification-actually-ran, scope discipline,
reliability (survives restart/rerun), maintainability, handoff readiness. Verdict: Accept / Revise
/ Block.

Evaluators need tuning: untuned evaluators identify real issues, then talk themselves into
approving anyway. Loop: run evaluator → compare with human judgment → where they diverge, make the
rubric's pass/fail criteria more specific → repeat. Plan 3–5 rounds.

### Sprint contract (align before coding)

For non-trivial tasks, agree scope *before* implementation so the evaluator doesn't reject for
foreseeable reasons:

```markdown
# Sprint Contract: <task>
## Scope        — what will be modified
## Verification — what standards must pass
## Exclusions   — what is explicitly out of scope
```

## Agent-Oriented Error Messages (WHAT / WHY / FIX)

Every check, lint rule, and test failure written for agents must include repair instructions —
this turns failures into a self-correction loop instead of blind retries:

```
ERROR: Direct import of 'firebase/firestore' in src/app/settings/page.tsx:12   (WHAT)
WHY:   Presentation layer must not touch the Firebase SDK (architecture rule)  (WHY)
FIX:   Import from the service layer instead, e.g. '@/domains/learning'        (FIX)
```

Bad: `"Test failed"`. Good: `"Test failed: POST /api/reset-password returned 500. Check that the
email service config exists in env vars; template expected at templates/reset-email.html."`

## Architectural Rules Must Be Executable

Rules that live only in documents drift; agents copy whatever patterns exist in the repo, good or
bad. Turn each architectural constraint into a mechanical check (lint rule, grep script, test) that
runs on every commit, with a WHAT/WHY/FIX message. Principle: **enforce invariants, don't
micromanage implementation** — require "data is validated at the boundary", don't prescribe the
library.

```bash
# Example: forbid Firebase SDK imports in presentation code
grep -rn "from ['\"]firebase/firestore" src/app src/domains/*/presentation && {
  echo "ERROR: firebase/firestore imported in presentation layer"
  echo "WHY:   Presentation → Application → Domain ← Infrastructure; SDK is Infrastructure-only"
  echo "FIX:   Import the service from the domain barrel or service file instead"
  exit 1
} || echo "OK: no direct SDK imports in presentation"
```

## Review-Feedback Promotion

Every time code review catches a category of agent mistake **twice**, promote it:

1. Write the rule down (topic doc or golden-rules section).
2. If mechanically checkable, encode it: lint rule, grep check, or test with WHAT/WHY/FIX output.
3. Add it to the verification pipeline so it runs on every session.

A month of this and the harness is materially stronger — captured human taste, enforced forever.

## Wiring Verification into a Repository

When applying this to a concrete repo, record these bindings in the repo's entry file (not here):

- **The single minimum gate** before any commit — one command, zero errors
  (e.g. `make check`, `pnpm lint && pnpm typecheck && pnpm build && pnpm test`).
- **The Layer-3 procedure** for changes that cross component boundaries — how to drive the real
  app through the changed flow (dev server + browser, curl against a running instance, CLI e2e).
- **The current mechanical checks** and where they live, plus candidates promoted from real review
  feedback (see Review-Feedback Promotion above).

Monorepo: the minimum gate is always the **root** fan-out command, never one app's filtered
command; contract changes between apps additionally require an end-to-end contract check. Details:
[monorepo.md](monorepo.md).
