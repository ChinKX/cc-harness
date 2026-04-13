# Harness: Status Check

Display the current state of the harness run.

## Process

1. Check if `.harness/` directory exists. If not, tell the user no harness run has been started and suggest `/harness-plan` or `/harness-run`.

2. Read and summarize each file that exists:

**PLAN.md** — List all phases with their names and criterion counts.

**STATE.md** — Show which phases are complete, in progress, or pending. Include any notes or concerns from the Generator.

**FEEDBACK.md** — Show the most recent evaluation verdict and any outstanding issues.

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
