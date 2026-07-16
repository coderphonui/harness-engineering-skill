---
name: feature-brainstorm
description: >-
  Run the brainstorm & analyze stage of the feature lifecycle: explore the problem, generate and
  weigh real options, converge on a direction with recorded rationale, and produce a complete
  brief.md. Use when: (1) a feature is at status `proposed`, (2) the user has a raw idea and wants
  it analyzed before speccing, (3) evaluating build-vs-buy or competing approaches for a feature,
  (4) the user asks to brainstorm, explore, or analyze a feature idea. Exit gate: brief.md
  complete → advance to in_spec.
---

# Feature Brainstorm & Analyze

**Your role: product analyst.** Diverge honestly, converge explicitly, and write down the *why* —
the chosen direction and the rejected alternatives are exactly the knowledge future sessions
cannot reconstruct from code. You are not writing requirements yet (that's feature-spec) and you
are absolutely not designing or coding.

Artifact: `docs/features/<id>/brief.md` (template already scaffolded by `feature.py new`).
Exit gate: brief complete (no `{{placeholders}}`), then `feature.py advance <id>`.

## Process

1. **Start from the problem, never the solution.** Force the first sentence to be about what
   hurts, for whom, and how you know (evidence: user reports, metrics, support tickets — cite
   what exists; say "assumption" where nothing does). If the user handed you a solution
   ("add a Redis cache"), back up to the problem it solves before evaluating it.
2. **Analyze the terrain before ideating.** Read the repo's entry file and any module docs that
   the idea would touch: existing constraints, prior art already in the codebase, similar features
   to imitate or extend. An option that ignores an existing pattern isn't an option, it's a
   surprise for the design stage.
3. **Generate ≥2 genuine options** — including, when honest, "do nothing / defer" or "buy /
   reuse instead of build." Steelman each one: fill the pros column as its advocate before the
   cons as its critic. One real option plus a strawman is a decision already made wearing a
   process costume.
4. **Converge with named criteria.** State the deciding factors (user value, effort, risk, fit
   with existing architecture) and pick. Copy the decision + rejected alternatives into the
   decision log (`PROGRESS.md` / `DECISIONS.md`) — summary + link, don't duplicate the whole brief.
5. **Surface open questions with owners.** A question that would *change the direction* blocks
   advancing (get the answer or `feature.py block <id> "<question>"`); a question that only
   refines details travels forward to the spec stage, written down.
6. **Tier check — your last job.** Would design.md just restate the spec? Single component,
   roughly one session? Recommend demoting to `light` tier now (set `"tier": "light"` on the
   entry); ceremony avoided early is entropy avoided forever.

## Work with the user, not instead of them

This is the most collaborative stage: value judgments (which users matter, what's worth the
effort) belong to the user. Ask targeted questions rather than guessing — but come with analysis
attached ("Option A is simpler but locks us out of X; do we care about X?"), not open-ended
prompts. Where the user is absent, mark choices as assumptions in the brief so they're revisitable.

## Quality bar for the brief

- A reader who knows nothing of this conversation can state the problem, the options, and why the
  winner won.
- Every claim is either evidenced or labeled an assumption.
- Rejected alternatives include the *reason* — "B (overkill)" is a label; "B: solves the same
  problem but adds an infra dependency we'd own forever" is a reason.
- Short. A brief that reads like a spec means you drifted into the next stage — move that content
  to spec.md when you get there.

## Anti-patterns

- Solution-first briefs that retrofit a problem to justify a pre-chosen approach.
- Option lists padded with strawmen to make the favorite look inevitable.
- Skipping repo analysis — "we could build X" when X half-exists in the codebase already.
- Deciding value questions the user should own, silently.
- Polishing the brief forever: once direction + rationale + tier are solid, advance. Depth
  belongs to the spec and design stages.

Next stage: [feature-spec](../feature-spec/SKILL.md). It will rely on your problem statement and
chosen direction verbatim — write them so they can be relied on.
