# Technical Design: {{title}}

Feature: `{{id}}` · Stage: **technical design** · Started: {{date}}

<!-- Exit gate: this file complete (no {{placeholders}}); in a monorepo, the feature entry's
     "affects" filled from Affected Components (change-scope triage). Design review happens
     HERE — a wrong design caught now costs minutes; caught in QA it costs the whole
     implementation. -->

## Approach Summary

{{How the chosen direction from brief.md becomes code — a paragraph, not a novel.}}

## Affected Components / Apps

<!-- Monorepo: this IS the change-scope triage. Copy the app/package list into the feature
     entry's "affects". -->

- {{component/app → what changes there}}

## Contracts Changed

<!-- API shapes, event schemas, shared-package public APIs, env vars other components read.
     A contract change requires BOTH sides updated and an end-to-end check — static checks
     compile clean while the system breaks at runtime. Write "none" if none. -->

- {{contract → both sides → e2e verification}}

## Data / State Changes

- {{schema, migration, persisted format changes — and rollback story. "none" if none.}}

## Risks & Mitigations

- {{risk → mitigation or accepted}}

## Implementation Plan

<!-- Ordered, one-session-sized steps. Each step should leave the repo in a committable,
     verification-green state. -->

1. {{step}}
2. {{step}}
