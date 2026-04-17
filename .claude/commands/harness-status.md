# Harness: Status Check

Display the current state of the harness run.

## Contract

### Inputs (read-only)
- `.harness/PLAN.md` frontmatter: `title`, `phase_count`, `task_type`; body phase list.
- `.harness/STATE.md` frontmatter: `phases_complete`, `current_phase`, `total_phases`.
- `.harness/FEEDBACK.md` frontmatter: `phase_id`, `iteration`, `verdict`, `criteria_met`, `criteria_total`.

### Outputs
- None to disk. Prints dashboard to console.

### Derivation rules (frontmatter-driven)
- Phase ∈ `phases_complete` → ✅ Complete
- Phase id == `current_phase` AND latest `FEEDBACK.md` has `verdict: REVISE` → 🔄 In Progress (show `iteration`)
- Otherwise → ⏳ Pending
- "Latest Evaluation" line: read directly from `FEEDBACK.md` frontmatter — do NOT re-parse the markdown body.

## Process

1. Check if `.harness/` directory exists. If not, tell the user no harness run has been started and suggest `/harness-plan` or `/harness-run`.

2. Read each file's YAML frontmatter (authoritative) plus the body (for human-readable details):

**PLAN.md** — Use frontmatter `title`, `phase_count`, `task_type` for the header; list all phases from the body with their criterion counts.

**STATE.md** — Use frontmatter `phases_complete` and `current_phase` to compute per-phase status; pull Generator notes from the body.

**FEEDBACK.md** — Use frontmatter `verdict`, `phase_id`, `iteration`, `criteria_met`/`criteria_total` for the latest-evaluation summary; pull outstanding issues from the body.

3. Print a dashboard:

```
====================================
  HARNESS STATUS
====================================
Plan: [title] — [N] phases

  Phase 1: [name]  ✅ Complete (1 iteration)
  Phase 2: [name]  🔄 In Progress (iteration 2)
  Phase 3: [name]  ⏳ Pending
  Phase 4: [name]  ⏳ Pending

Latest Evaluation: Phase 2 — REVISE
  ✅ 3/5 criteria passing
  ❌ 2 issues require fixes

Next action: /harness-generate 2
====================================
```

4. Suggest the appropriate next command based on the current state.
