# Clean State Checklist

<!-- A session is complete only when the task is verified AND every box below is checked. -->

- [ ] Standard startup path still works (`./init.sh` or documented equivalent)
- [ ] Full verification passes (build + tests + lint)
- [ ] `PROGRESS.md` updated (completed / verification / evidence / risks / next step)
- [ ] `feature_list.json` reflects reality — no false `passing`, single `in_progress`
- [ ] No stale artifacts: debug logs, scratch files, commented-out code, leftover debug prints
- [ ] No half-finished step left undocumented
- [ ] Work committed with a descriptive message
- [ ] Next session can continue without manual repair
