# Monorepo Harness

How to apply the five subsystems when one repository contains multiple applications or packages.
Read this whenever the target repo has workspace markers, then apply the relevant mode (audit /
scaffold / operate / verify) with the two-level rules below.

## Detecting a monorepo

Treat the repo as a monorepo when any of these exist:

- `pnpm-workspace.yaml`, `"workspaces"` in root `package.json`, `turbo.json`, `nx.json`,
  `lerna.json`, `rush.json`
- `go.work` (Go), `[workspace]` in root `Cargo.toml` (Rust), `melos.yaml` (Dart),
  multi-project `settings.gradle` (JVM), `uv`/Poetry workspace config (Python)
- Multiple independently deployable apps under `apps/`, `services/`, or similar, even without
  workspace tooling

Distinguish **apps** (independently deployed: web frontend, API, worker, mobile) from **shared
packages** (libraries consumed by apps). Both get harness coverage; apps get the full treatment,
shared packages get at least a contract statement (public API + who depends on it).

## The core rule: two levels, every subsystem

Every subsystem exists at the **root level** (cross-cutting) and the **app level** (per
deployable). A monorepo harness that only exists at the root leaves agents guessing inside each
app; one that only exists per-app leaves agents blind to cross-app impact. You need both:

| Subsystem | Root level | App level |
|---|---|---|
| Instructions | Router: repo map, cross-cutting hard rules, change-scope triage, session protocol, links to app entries | Nested entry file per app: architecture, constraints, gotchas, app DoD |
| Tools | Fan-out commands (`turbo run`, `nx run-many`, `pnpm -r`, `cargo --workspace`) | Filtered per-app commands (`pnpm --filter <app> …`, `nx run <app>:…`) |
| Environment | One root `init.sh` → verified baseline for ALL apps; root lockfile; pinned runtimes | App env vars/services documented in the app entry, with safe defaults or clear errors |
| State | One root `PROGRESS.md` + one feature list; features carry an `affects` scope | Decisions and known issues tagged with the app they concern |
| Feedback | Root verification command = the only definition-of-done gate | Per-app DoD checklist, app-specific verification steps, boundary checks |

## 1. Instructions: two-tier entry files

- **Root entry file** (`AGENTS.md` / `CLAUDE.md`) stays a router, 50–200 lines:
  what the repo is, the app map (one line per app: path, tech, deploy target), cross-cutting hard
  rules, the change-scope triage step (below), session protocol, root commands, and a link to each
  app's nested entry file.
- **Nested entry file per app** (`apps/<name>/AGENTS.md` or `apps/<name>/CLAUDE.md`, template:
  `assets/templates/AGENTS.app.md`): the app's architecture and constraints, its filtered commands,
  its DoD checklist, its contracts with other apps, and its gotchas. Claude Code auto-loads a
  nested `CLAUDE.md` when working in that subtree; Codex merges nested `AGENTS.md` files the same
  way. For agents that don't auto-load nested files, the root router's explicit links are the
  fallback — keep them current.
- **Growth rule**: new per-app detail goes in the nested file, never the root. The root file
  ballooning with app internals is the #1 monorepo instruction anti-pattern.
- Deeper topic docs (`apps/<name>/docs/…`) hang off the nested entry file with applicability
  conditions, exactly like topic docs in a single repo.

## 2. Tools: the command matrix

Document both layers explicitly in the root entry file:

- **Root fan-out**: the one command that verifies everything
  (e.g. `pnpm lint && pnpm typecheck && pnpm build && pnpm test` via Turbo/Nx fan-out).
- **Per-app iteration**: the filtered form (`pnpm --filter <app> test`, `nx run <app>:lint`,
  `cargo test -p <crate>`, `go test ./services/<app>/...`), documented in each app's entry.

Hard rule: **filtered commands are for iteration speed only; the definition-of-done gate is always
the root command.** A change verified only through one app's filter while it touched two apps is
the most common false "done" in monorepos.

## 3. Environment: one baseline, per-app prerequisites

- One root `init.sh` takes a fresh checkout to a verified baseline covering **all** apps. If one
  app's baseline is broken, the repo baseline is broken — fix before feature work, regardless of
  which app the feature targets.
- Each app's entry file documents its own prerequisites: env vars (with safe defaults or a clear
  WHAT/WHY/FIX error when missing), local services, seed data, emulators.
- Keep a single root lockfile and pinned runtime; per-app version drift is an environment bug.

## 4. State: one tracker, scoped entries

- **One** root `PROGRESS.md` and **one** feature list. Do not create per-app progress files or
  competing trackers — split state is how two half-truths replace one truth. (Exception: parallel
  agents each own a section or worktree-local file, merged at session end.)
- Every feature entry carries an `affects` field listing the apps/packages it touches
  (`"affects": ["web", "api"]`) — the output of change-scope triage, recorded before code is
  written.
- Decision log entries name the app(s) they concern so a future session working in one app can
  filter for relevant history.

## 5. Feedback: contracts are the monorepo-specific risk

Everything from [verification.md](verification.md) applies per app AND at the root. The additional
monorepo-specific machinery:

### Change-scope triage (run per feature, before code)

1. Which apps/packages does this change touch? Record in the feature's `affects`.
2. Does it change a **contract between apps** — an HTTP/RPC API shape, an event or queue schema,
   a shared package's public API, an env var another app reads?
3. If yes: list the required change on *each* side, and name the verification that exercises the
   contract end-to-end (contract test, e2e flow, or manual cross-app check). A contract change with
   only one side updated must be `blocked`, not `in_progress`.

This matters most when apps are **coupled only at runtime** (duplicated types across an HTTP
boundary): the compiler passes on both sides while the system is broken. Static checks are
structurally blind here; only Layer-3 (end-to-end) verification catches it.

### Boundary enforcement

Turn the architecture's allowed-dependency rules into mechanical checks with WHAT/WHY/FIX output:

- No cross-app imports except via declared shared packages (dependency-cruiser, ESLint
  `import/no-restricted-paths`, Nx `enforce-module-boundaries`, or a grep script).
- Shared packages never import from apps.
- A shared package's public API change requires checking every dependent
  (`turbo run build --filter=...^<pkg>`, `nx affected`, or grep for importers).

### Per-app definition of done

Each app's nested entry file carries its own DoD checklist (what "verified" means *for this app*:
which tests, which flows to drive, which deploy-target constraints). The root DoD = root
verification command passes + the DoD of every app in `affects` satisfied.

## Audit at the app level

The bundled `scripts/harness-audit.sh` detects workspace markers and adds a Monorepo section:
root-router checks plus a per-app sweep (does each app have a nested entry file? per-app commands?).
Beyond the script, run the **fresh-session test per app**: could a new session, told only "work on
`apps/X`", answer the five orientation questions (what is it, how organized, how to run, how to
verify, where are we) from repo contents alone? Score each app separately — monorepo harness
quality is the *minimum* across apps, not the average, because the weakest app is where the next
failure happens.

## Scaffold order for a monorepo

1. Root entry file (router + app map + change-scope triage + session protocol).
2. Nested entry file for **each deployable app** (`AGENTS.app.md` template), starting with the app
   that agents work in most.
3. Root `init.sh` covering all apps; per-app prerequisites into each nested entry.
4. Root `PROGRESS.md` + feature list with `affects` on every entry.
5. Boundary checks and contract verifications, promoted from the first cross-app incident (don't
   speculate all of them upfront — encode the ones that have actually bitten).

## Monorepo anti-patterns

- Root entry file containing app internals (architecture, gotchas) → move to nested entries.
- Per-app progress files or a second feature tracker → merge into the root tracker with `affects`.
- DoD gated on a filtered command → re-gate on the root command.
- Shared package changed, dependents unchecked → add a dependents check to verification.
- Contract change marked `passing` with only static verification → require the end-to-end check.
- A "shared architecture doc" at root that describes no app accurately → delete or move inside the
  app it actually describes and link it from that app's nested entry.
