# Progress Log

<!-- The single source of truth for project state. Every session reads this first and
     updates it before ending. Keep "Current Verified State" always accurate. -->

## Current Verified State

- Latest verified commit: {{hash + subject}}
- Standard startup path: {{command}}
- Standard verification path: {{command}} — status: {{passing / failing (what)}}
- Highest-priority unfinished feature: {{feature id + title}}
- Current blocker: {{none / description}}

## Decisions

<!-- Record the "why" — it is what gets lost between sessions. -->

### {{YYYY-MM-DD}}: {{decision title}}
- Decision: {{what was decided}}
- Reason: {{why}}
- Rejected alternative: {{what and why not}}

## Session Log

<!-- Newest first. One entry per session. -->

### Session {{NNN}} — {{YYYY-MM-DD}}
- Goal: {{planned work}}
- Completed: {{what actually got done}}
- Verification run: {{commands + results}}
- Evidence: {{test output, commit hashes, screenshots}}
- Commits: {{hashes}}
- Known risks / unresolved: {{anything possibly broken or unverified}}
- Next best step: {{where the next session should start}}
