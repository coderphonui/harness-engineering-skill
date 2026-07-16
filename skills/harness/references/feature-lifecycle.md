# Feature Development Lifecycle (opt-in)

An optional layer on top of the core harness that takes a feature from idea to shipped through
five staged gates: **brainstorm & analyze → requirement spec → technical design → implementation
→ QA & code review**. Use it when features are big enough that "start coding from a one-line
title" produces rework; skip it (or use light tier) when they aren't.

**The core harness works with or without this layer.** With the lifecycle off, features flow
`not_started → in_progress → passing` exactly as described everywhere else in this skill. Nothing
in the five subsystems depends on this file.

## Enabling

Set in `feature_list.json`:

```json
"rules": {
  "lifecycle": { "enabled": true, "default_tier": "full",
                 "stages": ["brainstorm", "spec", "design", "implement", "qa"] }
}
```

Or from scratch: `python3 <skill-dir>/scripts/feature.py init --lifecycle`.

## Stages, artifacts, gates

Each stage produces a named artifact and has a machine-checkable **exit gate** — a stage without
both is a label, and labels get skipped. Stage docs live in `docs/features/<id>/`, scaffolded from
`assets/templates/lifecycle/`.

| Stage | Status | Artifact | Exit gate (checked by `feature.py advance`) |
|---|---|---|---|
| Brainstorm & analyze | `proposed` | `brief.md` | Complete (no `{{placeholders}}`): problem, options, chosen direction, rejected alternatives |
| Requirement spec | `in_spec` | `spec.md` | Complete AND executable verification commands recorded on the feature entry |
| Technical design | `in_design` | `design.md` | Complete; monorepo: `affects` filled (this stage IS change-scope triage) |
| Implementation | `in_progress` | code + evidence | `feature.py verify` ran the entry's verification commands and they PASS |
| QA & code review | `in_qa` | `review.md` | An **independent** checker's `Verdict: Accept` |
| — | `passing` | | terminal; `blocked` reachable from any stage via `feature.py block` |

Two gates deserve emphasis:

- **Spec gate = executable acceptance criteria.** A spec is not done until its Verification Plan
  is copied into the entry's `verification` array. This front-loads the definition of done —
  the highest-leverage moment to write it.
- **QA gate = maker ≠ checker.** `review.md` is filled by a fresh session, evaluator agent, or
  human — never the implementer. The checker *re-runs* verification (does not trust the recorded
  run) and checks each acceptance criterion from `spec.md` with cited evidence. This is the
  skill's existing Verify mode formalized as a stage.

WIP=1 applies at the implementation gate: only one feature `in_progress` at a time. Upstream
stages (brief/spec/design) may proceed in parallel with another feature's implementation — writing
the next spec while the current feature is being built is healthy pipelining, not scope creep.

## Tiers: scale ceremony to feature size

- **`full`** — all five stages. For features that cross component/app boundaries, change
  contracts, or take more than a session or two.
- **`light`** — `not_started → in_progress → passing` (verification gate only, no stage docs).
  For small, single-component changes where a brief+spec+design would be entropy.

`rules.lifecycle.default_tier` sets the default; per-feature `"tier"` overrides it. The brief's
Tier Check section exists precisely to demote an idea to light tier early. When in doubt: a
feature whose design section would just restate its spec is light tier.

## The stage skills

Each stage has a companion skill installed alongside this one, defining that stage's **role**,
process, quality bar, and anti-patterns. When they are present, do stage work through them:

| Stage | Skill | Role |
|---|---|---|
| (routing) | `../../feature/SKILL.md` | lifecycle dispatcher — finds the stage, enforces handoffs |
| Brainstorm & analyze | `../../feature-brainstorm/SKILL.md` | product analyst — options, rationale, tier call |
| Requirement spec | `../../feature-spec/SKILL.md` | requirements engineer — falsifiable ACs, executable verification |
| Technical design | `../../feature-design/SKILL.md` | software architect — smallest design, contracts, step plan |
| Implementation | `../../feature-implement/SKILL.md` | disciplined implementer — WIP=1, per-step green commits |
| QA & code review | `../../feature-review/SKILL.md` | independent checker — re-run, cite, verdict (never the maker) |

(Paths are relative to this file's installed location; the skills are siblings of the harness
skill directory.) Without them, this file plus the templates carry the same rules — the skills
are packaging, not a dependency.

## The tool

`scripts/feature.py` (Python 3, stdlib only) mechanizes the flow — see `feature.py help`.
Typical full-tier run:

```bash
python3 <skill-dir>/scripts/feature.py new "Add item to cart" --area cart   # proposed + docs scaffolded
# ... fill docs/features/cart-001/brief.md ...
python3 <skill-dir>/scripts/feature.py advance cart-001                     # -> in_spec
# ... fill spec.md; copy Verification Plan into the entry ...
python3 <skill-dir>/scripts/feature.py advance cart-001                     # -> in_design
# ... fill design.md; fill affects (monorepo) ...
python3 <skill-dir>/scripts/feature.py advance cart-001                     # -> in_progress (WIP=1 enforced)
# ... implement ...
python3 <skill-dir>/scripts/feature.py verify cart-001                      # runs verification, records evidence
python3 <skill-dir>/scripts/feature.py advance cart-001                     # -> in_qa
# ... INDEPENDENT checker fills review.md, sets Verdict: Accept ...
python3 <skill-dir>/scripts/feature.py pass cart-001                        # -> passing
```

Gate failures print WHAT/WHY/FIX and exit nonzero, so the tool works as a script gate in loops
and CI as well as interactively.

**Gates guard forward moves only.** Going backward is always allowed and ungated —
`feature.py regress <id> [<stage>]` — because discovering that a stage's premise was wrong (QA
blocks, the design can't satisfy the spec, the spec contradicts the brief) must never be harder
than pushing forward. `block`/`unblock` is for external blockers (waiting on an answer, an API
key); `regress` is for rework. Regressions are stamped into the entry's `notes` so the history
of direction changes stays visible.

**The tool is an accelerator, not a dependency.** Every operation is a documented edit to
`feature_list.json` or a markdown file: an agent without Python (or a human in an editor) advances
a feature by completing the stage artifact and updating `status` by hand, honoring the same gates.
Never let a workflow depend on the tool being present — the files are the interface.

## Custom lifecycles (future)

The stage list lives in `rules.lifecycle.stages` as data. The shipped tool implements the default
five stages; a project needing a different pipeline (e.g. adding a security-review stage) can
today run the extra stage manually as a doc + checklist, and tooling can later read the stages
array without changing the file format. Keep any custom stage honest: named artifact + exit gate,
or it will be skipped.

## Where the lifecycle touches the rest of the harness

- **Session protocol** — clock-in step 3 ("read the feature list, pick ONE feature") is unchanged;
  a full-tier feature simply may not be at an implementable stage yet. `feature.py list` shows
  where everything stands.
- **Decision log** — the brief's Chosen Direction / Rejected Alternatives feed `PROGRESS.md` or
  `DECISIONS.md`; don't duplicate, summarize + link.
- **Sprint contract** — for full-tier features, `spec.md` + `design.md` supersede
  `sprint-contract.md` (scope, verification standards, exclusions all live in them). The sprint
  contract remains the lightweight middle ground for light-tier features that still want
  pre-agreed scope.
- **Evaluator rubric** — `review.md` applies its dimensions; keep tuning the rubric when checker
  verdicts diverge from human judgment.
- **Audit** — the audit script scores a Lifecycle section only when the layer is enabled;
  non-adopters are not penalized.

## Anti-patterns

- Stage docs written *after* the code to satisfy the gate → the gates lose meaning; if this
  happens, the feature belonged in light tier — demote next time instead of faking the pipeline.
- The implementer filling `review.md` → maker=checker; the verdict is invalid.
- Full tier as a blanket default on a repo of small features → ceremony, stale docs, entropy.
- `verification` filled with vague steps ("test manually") to pass the spec gate → the QA re-run
  becomes unfalsifiable; commands or scripted steps only.
- A second tracker (spreadsheet, issue board) holding the "real" stage while feature_list.json
  drifts → single source of truth; reconcile into the list.
