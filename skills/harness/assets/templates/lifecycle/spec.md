# Requirement Spec: {{title}}

Feature: `{{id}}` · Stage: **requirement spec** · Started: {{date}}

<!-- Exit gate: this file complete (no {{placeholders}}) AND the Verification Plan copied into
     the feature entry's "verification" array in feature_list.json. A spec is not done until
     its acceptance criteria are executable. -->

## User-Visible Behavior

{{One or two sentences: what a user sees when this works. Copy the essence into the feature
entry's "user_visible_behavior".}}

## Acceptance Criteria

<!-- Each criterion must be verifiable by a command or an observable step — "works well" is
     not a criterion. These become the QA checklist in review.md. -->

- [ ] AC1: {{criterion}}
- [ ] AC2: {{criterion}}

## Out of Scope

- {{explicitly not part of this feature — protects WIP=1 during implementation}}

## Edge Cases & Error Behavior

- {{input/state → expected behavior}}

## Verification Plan

<!-- Commands (or scripted steps) that prove the acceptance criteria. Copy into the feature
     entry's "verification" array — `feature.py verify {{id}}` will run them. -->

```
{{command 1}}
{{command 2}}
```
