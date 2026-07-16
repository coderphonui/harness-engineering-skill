# Evaluator Rubric

<!-- Used by an INDEPENDENT checker (fresh session, separate agent, or human) — never by the
     session that wrote the code. Cite evidence for every score; verdicts without evidence are
     invalid. Tune this rubric whenever its verdicts diverge from human judgment. -->

Task under review: {{feature id / description}}
Evaluator: {{fresh session / evaluator agent / human}}

| Dimension | Question | Score 0–2 | Evidence |
| --- | --- | --- | --- |
| Correctness | Does the implemented behavior match the requested feature? | | |
| Verification | Did the required checks actually run, with recorded results? | | |
| Scope discipline | Did the session stay inside the selected feature? | | |
| Reliability | Does the result survive restart / rerun without repair? | | |
| Maintainability | Is code + documentation clear enough for the next session? | | |
| Handoff readiness | Can a fresh session continue from repo artifacts alone? | | |

Scoring: 0 = fails · 1 = partial, with named gaps · 2 = meets the bar with evidence.

## Verdict

- [ ] **Accept** — all dimensions ≥1, correctness + verification = 2
- [ ] **Revise** — fixable gaps; list required fixes below
- [ ] **Block** — fundamental issue; do not build further on this work

## Required Follow-Up
- Missing evidence: {{...}}
- Required fixes: {{...}}
- Next review trigger: {{...}}
