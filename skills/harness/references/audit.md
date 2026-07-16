# Harness Audit Checklist

Manual audit rubric behind `scripts/harness-audit.sh`. Score each subsystem 0–5; report the
weakest subsystem and the 2–3 highest-impact fixes. The lowest score is a *candidate* bottleneck —
confirm against real failure history (which tasks failed, and why) before claiming causality.

## How to run an audit

1. Run `scripts/harness-audit.sh <target-dir>` for the mechanical checks below.
2. Run the **fresh-session test**: could a brand-new agent session, given only repo contents,
   answer — What is this system? How is it organized? How do I run it? How do I verify it? Where
   are we now? Each unanswerable question is a concrete gap.
3. If failure logs exist (or the user can describe recent agent failures), attribute each failure
   to a subsystem; weight the scores by observed failures.
4. Deliver: score table → weakest subsystem → top 2–3 fixes with the exact artifact to create or
   change → optionally offer Scaffold mode to apply them.

## 1. Instructions (entry file + topic docs)

- [ ] `AGENTS.md` or `CLAUDE.md` exists at repo root
- [ ] Entry file is 50–200 lines (router), or clearly sectioned with hard constraints at top/bottom
- [ ] Project overview: what the system is, in 1–2 sentences
- [ ] Global hard constraints listed (≤15), distinguishable from soft guidance
- [ ] Links to topic docs with applicability conditions ("read X when doing Y")
- [ ] Module-level docs (ARCHITECTURE.md / CONSTRAINTS.md) co-located with complex code
- [ ] No stale/contradictory rules (spot-check 5 rules against current code)

## 2. Tools

- [ ] Setup, test, lint, build, dev-server commands all documented in the entry file
- [ ] A single full-verification command exists (`make check`, `pnpm lint && pnpm build`, …)
- [ ] Tool/permission scoping present where the agent runtime supports it
- [ ] External integrations (MCP/connectors) documented if used

## 3. Environment

- [ ] Dependency lockfile committed
- [ ] Runtime version pinned (`.nvmrc`, `.python-version`, `.tool-versions`, `engines`, …)
- [ ] `init.sh` (or equivalent single command) takes a fresh checkout to a verified baseline
- [ ] Environment prerequisites (env vars, services) documented, with safe defaults or clear errors

## 4. State

- [ ] `PROGRESS.md` / `claude-progress.md` exists with a Current State block (commit, test status,
      next step)
- [ ] `feature_list.json` (or equivalent scope surface) exists; entries have behavior +
      verification + status; single `in_progress` at a time; `evidence` field present
- [ ] Decision rationale captured (in progress log or DECISIONS.md)
- [ ] Session handoff template or practice in place for long work
- [ ] Git history shows atomic commits with explanatory messages

## 5. Feedback

- [ ] Verification commands explicit and runnable, listed in the entry file
- [ ] Definition of done written down (evidence-based, layered static → runtime → e2e)
- [ ] WIP=1 rule stated in instructions
- [ ] Session start (clock-in) and end (clock-out) routines documented
- [ ] Clean-state / session-exit checklist exists
- [ ] Architectural constraints have mechanical checks with WHAT/WHY/FIX messages
- [ ] Evaluator rubric exists for reviewing agent output (maker ≠ checker)
- [ ] Quality document tracks per-domain/per-layer health over time

## 6. Monorepo (score only when workspace markers exist)

Apply when the repo has `pnpm-workspace.yaml`, `workspaces` in `package.json`, `turbo.json`,
`nx.json`, `lerna.json`, `go.work`, a `[workspace]` Cargo.toml, or multiple deployable apps.
Full guidance: [monorepo.md](monorepo.md).

- [ ] Root entry file maps the workspace: one line per app (path, tech, deploy target)
- [ ] Root entry file documents change-scope triage (which apps, contract changes, both-sides rule)
- [ ] Every deployable app has a nested entry file (`apps/<x>/AGENTS.md` or `CLAUDE.md`) with
      app-specific constraints, commands, and DoD — root file free of app internals
- [ ] Both command layers documented: root fan-out AND per-app filtered commands
- [ ] Definition-of-done gate is the root verification command, not a filtered one
- [ ] One root progress log + one feature tracker; feature entries carry an `affects` scope
- [ ] Cross-app contracts listed in each app's entry (provides/consumes + how verified)
- [ ] Boundary rules mechanically enforced (no cross-app imports; shared packages never import apps)
- [ ] Root `init.sh` verifies all apps from a fresh checkout
- [ ] Fresh-session test passes **per app** (score each; harness quality = the minimum, not the
      average)

## 7. Feature Lifecycle (score only when the project has opted in)

Apply only when `rules.lifecycle.enabled` is true in `feature_list.json` or `docs/features/`
stage docs exist. Never penalize a project for not adopting the lifecycle — it is an opt-in
layer. Full guidance: [feature-lifecycle.md](feature-lifecycle.md).

- [ ] Lifecycle rules present in `feature_list.json` (enabled, default_tier, stages)
- [ ] `docs/features/<id>/` exists per full-tier feature with the stage artifacts
      (`brief.md`, `spec.md`, `design.md`, `review.md`)
- [ ] Completed-stage docs have no `{{placeholders}}` left (spot-check 2–3)
- [ ] Specs end in executable verification commands, copied into the entry's `verification`
- [ ] Verification runs are recorded (`last_verification` / "verify PASS" evidence entries)
- [ ] `review.md` files carry explicit verdicts, filled by an independent checker
- [ ] Tiering is actually used — small features are `light`, not full-ceremony
- [ ] No stage docs written after the fact just to satisfy gates (compare doc vs. commit dates)

## Scoring

Per subsystem: 0 = absent · 1–2 = partial, agent still guesses · 3–4 = present and usable ·
5 = present, current, and mechanically enforced where possible.

Priority order when everything is weak: **Feedback → Instructions → State → Environment → Tools**
(feedback is the highest-ROI subsystem; tools are usually fine by default).

## Anti-patterns to flag

- Entry file > 300 lines with mixed constraint priorities → split into topic docs
- Critical constraint in the middle of a long file → move to top/bottom or topic doc
- Feature states editable by assertion (no verification gate) → gate transitions on commands
- Progress notes like "mostly done" → require verified/unverified with evidence
- Docs contradicting code → delete or fix; stale docs are worse than none
- Harness components nobody can justify → candidate for the simplification test
  (disable → benchmark → remove or restore)
