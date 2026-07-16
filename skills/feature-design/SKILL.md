---
name: feature-design
description: >-
  Run the technical design stage of the feature lifecycle: choose the smallest architecture that
  satisfies the spec, map affected components (change-scope triage in monorepos), name changed
  contracts and their end-to-end checks, and produce design.md with a one-session-sized
  implementation plan. Use when: (1) a feature is at status `in_design`, (2) the user asks for a
  technical design, architecture proposal, or implementation plan for a feature, (3) a change
  might cross app/package boundaries and needs scope triage. Exit gate: design.md complete
  (+ `affects` filled in a monorepo) → advance to in_progress.
---

# Feature Technical Design

**Your role: software architect.** Decide HOW, inside the constraints the repo already has. The
spec's acceptance criteria are fixed inputs — if the design work reveals the spec is wrong or
unimplementable, push back a stage explicitly; never "design around" the spec so that what gets
built quietly differs from what was agreed.

Artifact: `docs/features/<id>/design.md`. Exit gate: design complete; in a monorepo, the entry's
`affects` filled — **this stage IS the change-scope triage**. Entering implementation also
triggers the WIP=1 check, so a design advanced too early parks the whole pipeline.

## Process

1. **Read before you invent**: `spec.md` (and `brief.md` for rationale), the repo entry file, the
   architecture/topic docs of every area you might touch, and — in a monorepo — the nested entry
   file of each candidate app. Then look at *actual code*: the pattern the repo already uses for
   a problem beats the pattern you'd choose fresh. Consistency is a feature; novelty is a cost.
2. **Smallest design that satisfies the spec.** State invariants, not implementations: "cart
   state is validated at the API boundary" survives refactors; "use zod schema in file X" is
   micromanagement the implementer may rightly improve on. Design for the acceptance criteria
   that exist, not the features that might come.
3. **Affected components / change-scope triage.** List every app/package/module that changes.
   Monorepo: copy the app list into the entry's `affects`; if more than one app appears,
   remember the root-command DoD gate applies (see
   [../harness/references/monorepo.md](../harness/references/monorepo.md)).
4. **Contracts changed — the section that prevents runtime breakage.** For each API shape, event
   schema, shared-package public API, or env var another component reads: name both sides'
   required changes and the end-to-end check that will exercise the contract. Duplicated types
   across an HTTP boundary compile green on both sides while broken at runtime — if a contract
   changes and no e2e check is named, the design is incomplete.
5. **Data/state changes** with a rollback story. A migration without a way back is a decision to
   accept irreversibility — make that explicit, don't imply it.
6. **Risks & mitigations** — the 2–3 things most likely to sink this, each with a mitigation or
   an explicit "accepted."
7. **Implementation plan: ordered, one-session-sized, committable steps.** Each step should leave
   the repo verification-green and committable — that's what makes the plan resumable across
   sessions and safe to hand to any implementer. A step that can't be verified until three steps
   later is one step, not three.

## Design review — cheap insurance

For full-tier features that change contracts or touch several components, get the design reviewed
by a fresh session, sub-agent, or human *before* advancing: a wrong design caught now costs
minutes; caught in QA it costs the entire implementation. The reviewer checks: does it satisfy
every AC? does it violate any documented constraint? is anything simpler? Record the outcome in
the design doc.

## Quality bar

- Someone else could implement this without making an architectural decision of their own.
- Every AC in spec.md is traceable to some part of the design; every design element earns its
  place by serving an AC or a documented constraint.
- Monorepo: `affects` matches the Affected Components section exactly.
- The plan's first step is startable immediately after `advance` — no hidden prerequisites.

## Anti-patterns

- Designing in a vacuum: proposing a second convention for something the repo already does one
  way (agents copy patterns — a second pattern is permanent confusion).
- Speculative generality — plugin systems, abstraction layers, config surface for requirements
  nobody specced.
- "Contracts: none" written reflexively; grep for consumers before you claim it.
- A plan with steps like "implement the feature" — if a step isn't one session and one commit,
  it isn't a step; decompose it.
- Silently narrowing the spec because the honest design is harder — renegotiate, don't erode.

Next stage: [feature-implement](../feature-implement/SKILL.md). Your implementation plan becomes
its checklist; your invariants become its guardrails.
