# {{app name}} — Agent Instructions

<!-- Nested entry file for ONE app inside a monorepo, e.g. apps/web/AGENTS.md or
     apps/api/CLAUDE.md. Claude Code auto-loads a nested CLAUDE.md in this subtree; Codex merges
     nested AGENTS.md; other agents reach this via the link in the root entry file.
     Keep it 30–150 lines. Per-app detail belongs HERE, never in the root router.
     Replace every {{placeholder}}. -->

{{One or two sentences: what this app is, its tech stack, and its deploy target.}}

Root rules still apply: read the root entry file for cross-cutting constraints, the change-scope
triage step, and the session protocol. This file adds only what is specific to this app.

## Commands (this app only)

- Iterate: `{{filtered command, e.g. pnpm --filter {{app}} test / nx run {{app}}:lint}}`
- Dev server: `{{filtered dev command}}`

**These are for iteration speed only. The definition-of-done gate is always the ROOT verification
command** (`{{root verify command}}`), never a filtered command.

## Environment (this app only)

- Required env vars: `{{VAR — purpose, safe default or failure behavior}}`
- Local services / seed data: `{{none / description}}`

## Architecture & Hard Constraints

<!-- ≤10 rules specific to this app. Cross-cutting rules stay in the root entry file. -->

- {{constraint 1, e.g. presentation layer never imports the DB client}}
- {{constraint 2}}

## Contracts with Other Apps

<!-- The monorepo-specific risk: changes here that break another app at runtime while the
     compiler stays green. List every contract this app provides or consumes. -->

- Provides: {{e.g. HTTP API at /api/* — consumed by apps/web; shapes defined in {{path}}}}
- Consumes: {{e.g. calls apps/api at {{env var}}; response types duplicated in {{path}} — a
  contract change compiles on both sides but breaks at runtime}}
- Contract verification: {{the end-to-end or contract test that exercises each contract}}

## Definition of Done (this app)

A change touching this app is done only when:

- {{app-specific verification, e.g. its test suite passes / the changed flow was driven in a
  real browser / the endpoint was exercised with curl}}
- the root verification command passes
- if a contract in the section above changed: the contract verification ran on both sides

## Gotchas

<!-- Traps that have actually bitten a session. Delete entries that stop being true. -->

- {{gotcha 1}}

## Topic Docs (this app)

- `{{docs/x.md}}` — read when {{condition}}
