# Harness Contracts & Task-Type Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the two README roadmap items: (1) formalize expected outputs for every agent via frontmatter contracts; (2) support non-coding tasks (writing, research, design) by routing evaluation style on a `task_type` field.

**Architecture:** Each agent's markdown prompt file gains a **Contract** section that specifies preconditions, the exact YAML frontmatter its output artifact must carry, and the controlled vocabulary for enum fields. Orchestrator and Status then drive control flow by reading frontmatter (structured) rather than parsing prose. Phase 2 extends the `task_type` enum and adds per-type criterion templates + evaluator strategies.

**Tech Stack:** Claude Code slash commands (markdown prompt files under `.claude/commands/`). No runtime code — artifacts are markdown files with YAML frontmatter in `.harness/`.

---

## Design decisions (resolved)

- **Criteria revisions mid-flight:** OUT OF SCOPE. Criteria remain frozen after `/harness-plan` until a human edits `PLAN.md` by hand. Revisit after Phases 1–2 ship.
- **Per-task-type criterion style:** IN SCOPE for Phase 2. Each `task_type` carries its own criterion template + evaluator strategy.
- **Frontmatter format:** YAML (Claude Code commands + `.harness/` artifacts are already markdown; YAML frontmatter is conventional and readable by both humans and regex).
- **Plan structure stays markdown with frontmatter** (Option A from the conversation), not JSON sidecars. Lighter touch, one file per artifact.
- **Version field on every artifact:** `version: 1` — makes future schema migrations possible.

## Current state (pre-existing WIP)

- `/.claude/commands/harness-plan.md` already has a **Contract** section added (preconditions, frontmatter spec, vocabulary). Still needs: the **Output** section's PLAN.md template updated to include the frontmatter block at the top. Reflected in Task 1.1.
- No other files modified yet.

## File Structure

**Modified (5 files):**
- `.claude/commands/harness-plan.md` — Planner: writes `PLAN.md` with frontmatter.
- `.claude/commands/harness-generate.md` — Generator: writes/updates `STATE.md` with frontmatter.
- `.claude/commands/harness-evaluate.md` — Evaluator: writes `FEEDBACK.md` with frontmatter (incl. `verdict` enum).
- `.claude/commands/harness-run.md` — Orchestrator: reads frontmatter to decide control flow.
- `.claude/commands/harness-status.md` — Status: reads frontmatter to build dashboard.

**Modified (1 file, Phase 2 only):**
- `README.md` — document `task_type` usage; mark roadmap items done.

**No new files required.** (The plan file itself lives in `docs/superpowers/plans/`.)

## Controlled vocabulary (shared across all artifacts)

Any agent modifying an artifact MUST use these exact values:

| Field | Artifact | Values |
|---|---|---|
| `harness_artifact` | all | `plan` \| `state` \| `feedback` |
| `version` | all | integer, currently `1` |
| `task_type` | PLAN.md | Phase 1: `code`. Phase 2: `code` \| `writing` \| `research` \| `design` |
| `verdict` | FEEDBACK.md | `APPROVE` \| `REVISE` \| `BLOCK` |
| `phase_status` (implicit via `phases_complete` list) | STATE.md | present in list → complete; absent → pending |

## Frontmatter schemas (targets)

### PLAN.md
```yaml
---
harness_artifact: plan
version: 1
title: <short title>
task_type: code
phase_count: <integer>
---
```

### STATE.md
```yaml
---
harness_artifact: state
version: 1
current_phase: <integer>        # phase most recently worked on
phases_complete: [<integer>, ...]
total_phases: <integer>
---
```

### FEEDBACK.md
```yaml
---
harness_artifact: feedback
version: 1
phase_id: <integer>
iteration: <integer>            # 1-indexed; increments on re-eval after REVISE
verdict: APPROVE                # one of APPROVE | REVISE | BLOCK
criteria_total: <integer>
criteria_met: <integer>
---
```

---

## Phase 1 — Formalize output contracts (TODO 1)

### Task 1.1: Finish harness-plan.md (Planner contract)

**Files:**
- Modify: `.claude/commands/harness-plan.md`

- [ ] **Step 1: Verify Contract section is already present**

Run: `grep -n "^## Contract" /Users/kaixiang.chin/Desktop/dev/cc-harness/.claude/commands/harness-plan.md`
Expected: one match (WIP from prior edit). If missing, add the Contract block per the frontmatter schema above before continuing.

- [ ] **Step 2: Update the Output template to include frontmatter**

Inside the `## Output` section, replace the existing template opening:

```markdown
Write the spec to `.harness/PLAN.md` using this structure:

```markdown
# Plan: [Short Title]
```

with:

```markdown
Write the spec to `.harness/PLAN.md` using this structure:

```markdown
---
harness_artifact: plan
version: 1
title: [Short Title]
task_type: code
phase_count: [N]
---

# Plan: [Short Title]
```

- [ ] **Step 3: Verify**

Run: `grep -c "harness_artifact: plan" /Users/kaixiang.chin/Desktop/dev/cc-harness/.claude/commands/harness-plan.md`
Expected: `2` (one in the Contract's required-frontmatter block, one in the Output template).

- [ ] **Step 4: Commit**

```bash
git add .claude/commands/harness-plan.md
git commit -m "harness: add contract + frontmatter schema to Planner"
```

### Task 1.2: harness-generate.md (Generator contract)

**Files:**
- Modify: `.claude/commands/harness-generate.md`

- [ ] **Step 1: Insert Contract section after `## Input`**

Add immediately before `## Before You Start`:

```markdown
## Contract

### Preconditions
- `.harness/PLAN.md` exists and contains `phase_count` in its frontmatter.
- Target phase is identified: `$ARGUMENTS` if provided, otherwise the smallest phase id in `[1..phase_count]` not present in `.harness/STATE.md` frontmatter `phases_complete`.
- If `.harness/FEEDBACK.md` exists with `verdict: REVISE`, every issue listed must be addressed before the phase can be marked complete.

### Output artifact
- `.harness/STATE.md` — created if missing, otherwise updated. Frontmatter is overwritten; body section for the current phase is appended.

**Required frontmatter (overwrite on every update):**
```yaml
---
harness_artifact: state
version: 1
current_phase: <integer>
phases_complete: [<integer>, ...]   # add current phase id only when all its acceptance criteria self-check as met
total_phases: <integer>
---
```

### Side effect
- One git commit per phase: `harness: complete phase N — [phase name]`.
```

- [ ] **Step 2: Update the STATE.md body template in Process step 4**

Change the existing block from:

```markdown
4. **Update state** — append to `.harness/STATE.md`:

```markdown
## Phase N: [Name]
- **Status:** complete
- **Timestamp:** [current time]
- **Notes:** [any implementation decisions, deviations from plan, or concerns]
- **Files changed:** [list of files created/modified]
```

to:

```markdown
4. **Update state** — ensure `.harness/STATE.md` has the required frontmatter (create if missing, otherwise overwrite to reflect the new `current_phase` and updated `phases_complete` list), then append a phase block to the body:

```markdown
---
harness_artifact: state
version: 1
current_phase: N
phases_complete: [..., N]
total_phases: M
---

## Phase N: [Name]
- **Status:** complete
- **Timestamp:** [current time]
- **Notes:** [any implementation decisions, deviations from plan, or concerns]
- **Files changed:** [list of files created/modified]
```

- [ ] **Step 3: Verify**

Run: `grep -c "harness_artifact: state" /Users/kaixiang.chin/Desktop/dev/cc-harness/.claude/commands/harness-generate.md`
Expected: `2`.

- [ ] **Step 4: Commit**

```bash
git add .claude/commands/harness-generate.md
git commit -m "harness: add contract + frontmatter schema to Generator"
```

### Task 1.3: harness-evaluate.md (Evaluator contract)

**Files:**
- Modify: `.claude/commands/harness-evaluate.md`

- [ ] **Step 1: Insert Contract section after `## Input`**

Add immediately before `## Before You Start`:

```markdown
## Contract

### Preconditions
- `.harness/PLAN.md` exists with the target phase in its body.
- `.harness/STATE.md` exists with the target phase listed in `phases_complete`.
- Target phase is identified: `$ARGUMENTS` if provided, otherwise `current_phase` from `STATE.md` frontmatter.

### Output artifact
- `.harness/FEEDBACK.md` — overwritten on every evaluation.

**Required frontmatter:**
```yaml
---
harness_artifact: feedback
version: 1
phase_id: <integer>
iteration: <integer>              # 1 for first eval of this phase; increments on re-eval after REVISE
verdict: APPROVE                   # one of APPROVE | REVISE | BLOCK
criteria_total: <integer>
criteria_met: <integer>
---
```

### Vocabulary
- `verdict`:
  - `APPROVE` — all acceptance criteria PASS. Orchestrator advances to next phase.
  - `REVISE` — one or more criteria FAIL or PARTIAL. Orchestrator re-runs the Generator for this phase.
  - `BLOCK` — critical issue, or `iteration >= 3` with unresolved failures. Orchestrator stops and escalates to human.
- `iteration`: must strictly increment by 1 across re-evaluations of the same `phase_id`. If prior `FEEDBACK.md` exists for this phase, read its `iteration` and add 1.
```

- [ ] **Step 2: Update the FEEDBACK.md template in the `## Output` section**

Replace the template opening from:

```markdown
Write your evaluation to `.harness/FEEDBACK.md` (overwrite previous contents):

```markdown
# Evaluation: Phase [N] — [Name]
```

with:

```markdown
Write your evaluation to `.harness/FEEDBACK.md` (overwrite previous contents):

```markdown
---
harness_artifact: feedback
version: 1
phase_id: [N]
iteration: [K]
verdict: [APPROVE | REVISE | BLOCK]
criteria_total: [T]
criteria_met: [M]
---

# Evaluation: Phase [N] — [Name]
```

- [ ] **Step 3: Align the Recommendation line with the frontmatter verdict**

In the FEEDBACK.md body template, the existing `## Recommendation` line reads `[APPROVE to move to next phase | REVISE and re-evaluate | BLOCK with critical issues]`. Add one sentence immediately after the `## Recommendation` heading (inside the template):

> The value in the `verdict` frontmatter field MUST match the choice on this line.

- [ ] **Step 4: Verify**

Run: `grep -c "harness_artifact: feedback" /Users/kaixiang.chin/Desktop/dev/cc-harness/.claude/commands/harness-evaluate.md`
Expected: `2`.

- [ ] **Step 5: Commit**

```bash
git add .claude/commands/harness-evaluate.md
git commit -m "harness: add contract + frontmatter schema to Evaluator"
```

### Task 1.4: harness-run.md (Orchestrator control-flow contract)

**Files:**
- Modify: `.claude/commands/harness-run.md`

- [ ] **Step 1: Insert Contract section after `## Input`**

Add immediately before `## Workflow`:

```markdown
## Contract

### Inputs (read-only)
- `.harness/PLAN.md` — frontmatter fields `phase_count`, `task_type`; body phase definitions.
- `.harness/STATE.md` — frontmatter fields `phases_complete`, `current_phase`, `total_phases`.
- `.harness/FEEDBACK.md` — frontmatter fields `verdict`, `iteration`, `phase_id`.

### Control flow (driven by frontmatter, NOT prose)
- **Next phase to generate:** smallest integer in `[1..phase_count]` not in `STATE.md`'s `phases_complete`.
- **After each evaluation, read `FEEDBACK.md` frontmatter `verdict`:**
  - `APPROVE` → advance: add `phase_id` to `phases_complete`, run Generator for the next phase.
  - `REVISE` → if `iteration < 3`, re-run Generator for the same `phase_id`; otherwise treat as `BLOCK`.
  - `BLOCK` → append a BLOCKED note to `STATE.md`, print final summary, stop.
- **Never parse the prose recommendation line** — it is a human-readable mirror of the `verdict` field; the field is authoritative.
```

- [ ] **Step 2: Verify**

Run: `grep -c "driven by frontmatter" /Users/kaixiang.chin/Desktop/dev/cc-harness/.claude/commands/harness-run.md`
Expected: `1`.

- [ ] **Step 3: Commit**

```bash
git add .claude/commands/harness-run.md
git commit -m "harness: document Orchestrator's frontmatter-driven control flow"
```

### Task 1.5: harness-status.md (Status reads frontmatter)

**Files:**
- Modify: `.claude/commands/harness-status.md`

- [ ] **Step 1: Insert Contract section after the opening description, before `## Process`**

Add:

```markdown
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
```

- [ ] **Step 2: Update Process step 2 to cite frontmatter sources explicitly**

Replace the existing:

```markdown
2. Read and summarize each file that exists:

**PLAN.md** — List all phases with their names and criterion counts.

**STATE.md** — Show which phases are complete, in progress, or pending. Include any notes or concerns from the Generator.

**FEEDBACK.md** — Show the most recent evaluation verdict and any outstanding issues.
```

with:

```markdown
2. Read each file's YAML frontmatter (authoritative) plus the body (for human-readable details):

**PLAN.md** — Use frontmatter `title`, `phase_count`, `task_type` for the header; list all phases from the body with their criterion counts.

**STATE.md** — Use frontmatter `phases_complete` and `current_phase` to compute per-phase status; pull Generator notes from the body.

**FEEDBACK.md** — Use frontmatter `verdict`, `phase_id`, `iteration`, `criteria_met`/`criteria_total` for the latest-evaluation summary; pull outstanding issues from the body.
```

- [ ] **Step 3: Verify**

Run: `grep -c "frontmatter-driven" /Users/kaixiang.chin/Desktop/dev/cc-harness/.claude/commands/harness-status.md`
Expected: `1`.

- [ ] **Step 4: Commit**

```bash
git add .claude/commands/harness-status.md
git commit -m "harness: document Status's frontmatter-driven rendering"
```

### Task 1.6: Smoke test — full /harness-run on a tiny spec

**Files:**
- No code changes. Runtime verification only.

- [ ] **Step 1: Run the pipeline on a trivial task**

In Claude Code, invoke:
```
/harness-run Build a Python script hello.py that prints "hello harness"
```

- [ ] **Step 2: Verify all three artifacts carry correct frontmatter**

After the run completes:
```bash
head -8 .harness/PLAN.md
head -8 .harness/STATE.md
head -8 .harness/FEEDBACK.md
```
Expected: each file begins with a YAML block containing `harness_artifact: {plan|state|feedback}` and `version: 1`. PLAN.md has `task_type: code` and an integer `phase_count`. STATE.md has `phases_complete` as a YAML list. FEEDBACK.md has `verdict` ∈ {APPROVE, REVISE, BLOCK}.

- [ ] **Step 3: Verify Orchestrator consumed frontmatter correctly**

Check the run output: each transition line (`[Harness] Phase N APPROVED…` etc.) must correspond to the `verdict` field actually written in `FEEDBACK.md` at that iteration.

- [ ] **Step 4: Tear down the smoke-test artifacts**

```bash
rm -rf .harness hello.py
```

(No commit — this is a validation-only step.)

### Task 1.7: Update README roadmap

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Check off TODO 1 in the roadmap**

Replace:
```
- [] Define the expected outputs for every step/agent
```
with:
```
- [x] Define the expected outputs for every step/agent (YAML frontmatter contracts — see `.claude/commands/*`)
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: mark TODO 1 (agent output contracts) complete"
```

---

## Phase 2 — Task-type support (TODO 2)

### Task 2.1: Expand `task_type` vocabulary and add inference guidance

**Files:**
- Modify: `.claude/commands/harness-plan.md`

- [ ] **Step 1: Update Contract vocabulary**

In the `## Contract` → `### Vocabulary` subsection, replace:
```
- `task_type` enum: `code` (sole supported value today; other values reserved for future task-type routing).
```
with:
```
- `task_type` enum:
  - `code` — software implementation; criteria are runnable commands or file-existence checks.
  - `writing` — prose artifacts (docs, blog posts, reports); criteria are rubric dimensions (clarity, coverage, factual accuracy, tone) with PASS/FAIL per dimension.
  - `research` — synthesis of external sources; criteria are (a) required sub-questions answered, (b) every factual claim grounded in at least one cited source.
  - `design` — visual/UX artifacts (mockups, wireframes); criteria are screenshot-based checks (component present, layout matches reference, accessibility annotations).
- **Inference:** if the user does not specify `task_type`, the Planner picks one based on the request. Prefer `code` when the request names a language, framework, CLI, API, or file extension; otherwise pick the closest non-code type. When ambiguous, pick `code` and note the assumption under `## Risks & Open Questions` in the plan body.
```

- [ ] **Step 2: Add a per-type criterion style guide in the Process section**

Inside `## Your Process`, after step 4 (Define success criteria), append:

```markdown
5. **Write criteria in the style that matches `task_type`:**
   - `code` — runnable commands with expected output: `running \`python hello.py\` prints "hello harness"`.
   - `writing` — rubric items with explicit pass conditions: `The Overview section names the problem, the audience, and at least two concrete examples`.
   - `research` — evidence requirements: `Every numeric claim in §2 cites a source in the Sources section`.
   - `design` — observable visual properties: `The header contains a logo, three nav items, and a primary CTA, arranged left-to-right`.
```

- [ ] **Step 3: Verify**

Run: `grep -c "writing\|research\|design" /Users/kaixiang.chin/Desktop/dev/cc-harness/.claude/commands/harness-plan.md`
Expected: at least `6` (each type mentioned at least twice — in vocabulary and in process guide).

- [ ] **Step 4: Commit**

```bash
git add .claude/commands/harness-plan.md
git commit -m "harness: expand task_type vocabulary + per-type criterion style"
```

### Task 2.2: Generator adapts artifacts to `task_type`

**Files:**
- Modify: `.claude/commands/harness-generate.md`

- [ ] **Step 1: Add a Process step that branches on `task_type`**

In `## Your Process`, insert a new step 1 (renumbering the rest):

```markdown
1. **Read `task_type` from `.harness/PLAN.md` frontmatter** and select your output mode:
   - `code` — produce source files, tests, and a git commit as described below. Run the code to self-check.
   - `writing` — produce prose files (e.g., `docs/<slug>.md`, `content/<slug>.md`). Do NOT create source files unless the phase explicitly requires them. Still commit.
   - `research` — produce a structured report file (e.g., `research/<slug>.md`) with a Sources section at the bottom. Every factual claim must link to an entry in Sources. Still commit.
   - `design` — produce an artifact reference file (e.g., `design/<slug>.md`) describing the screens/components delivered, with paths to any exported images. Still commit.
```

- [ ] **Step 2: Update the Rules section**

In `## Rules`, after "Stay in scope", append a new bullet:
```
- **Honor the `task_type`.** Do not over-reach beyond what the task type calls for (e.g., don't generate code for a `writing` task just because the Planner's criteria felt ambiguous — escalate instead).
```

- [ ] **Step 3: Verify**

Run: `grep -c "task_type" /Users/kaixiang.chin/Desktop/dev/cc-harness/.claude/commands/harness-generate.md`
Expected: at least `3`.

- [ ] **Step 4: Commit**

```bash
git add .claude/commands/harness-generate.md
git commit -m "harness: Generator branches output mode on task_type"
```

### Task 2.3: Evaluator adapts strategy to `task_type`

**Files:**
- Modify: `.claude/commands/harness-evaluate.md`

- [ ] **Step 1: Add a Process preamble that selects evaluation strategy**

In `## Your Process`, insert a new first paragraph (before the numbered list):

```markdown
**Select your evaluation strategy from `task_type` (in `.harness/PLAN.md` frontmatter):**
- `code` — **run** things: execute commands, check file existence, verify outputs. Reading code is not testing.
- `writing` — **grade** against the rubric: for each rubric criterion, read the produced prose and judge PASS/FAIL with a one-sentence justification quoting the relevant text.
- `research` — **audit citations**: for every factual claim in the output, verify (a) the claim is accompanied by a citation and (b) the citation points to a real, retrievable source. Spot-check at least three citations.
- `design` — **inspect visuals**: load any referenced screenshots/images and verify the observable properties listed in the criteria. Note missing or mismatched elements.

For all types, continue with the numbered process below; the *action verbs* in step 1 ("run the code", "execute commands") should be translated into the equivalent action for your strategy.
```

- [ ] **Step 2: Update Rules**

In `## Rules`, modify the "Actually run things" bullet to read:
```
- **Actually exercise the artifact.** For `code` tasks: run it. For `writing`: read every section and test rubric items against the text. For `research`: open cited sources. For `design`: view the images. Reading a prompt and imagining the result is not evaluation.
```

- [ ] **Step 3: Verify**

Run: `grep -c "task_type" /Users/kaixiang.chin/Desktop/dev/cc-harness/.claude/commands/harness-evaluate.md`
Expected: at least `2`.

- [ ] **Step 4: Commit**

```bash
git add .claude/commands/harness-evaluate.md
git commit -m "harness: Evaluator selects strategy from task_type"
```

### Task 2.4: README documents the new `task_type` axis

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add a "Task types" subsection under "Adapting the harness"**

Insert immediately before `## Credits`:

```markdown
## Task types

The harness supports four `task_type` values (auto-inferred by the Planner; override by editing `.harness/PLAN.md` after `/harness-plan`):

| `task_type` | Artifact style | Criterion style | Evaluator strategy |
|---|---|---|---|
| `code` | source files, tests | runnable commands | execute and verify |
| `writing` | prose (Markdown) | rubric items | judge against rubric |
| `research` | report with Sources | claim-citation requirements | audit citations |
| `design` | screens + image refs | observable visual properties | inspect screenshots |

Mix-and-match is explicitly out of scope for a single run — one plan, one `task_type`. Split multi-modal projects into multiple runs.
```

- [ ] **Step 2: Check off TODO 2 in the roadmap**

Replace:
```
- [] Support variety of tasks. Currently, only general coding tasks
```
with:
```
- [x] Support variety of tasks via `task_type` (code | writing | research | design)
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: task_type section + mark TODO 2 complete"
```

### Task 2.5: Smoke test — writing task end-to-end

**Files:**
- No code changes. Runtime verification only.

- [ ] **Step 1: Run the pipeline on a writing task**

In Claude Code:
```
/harness-run Write a 300-word overview of the harness pattern for our engineering blog, with a hook, two concrete examples, and a closing call-to-action.
```

- [ ] **Step 2: Verify task_type inference**

```bash
grep "task_type:" .harness/PLAN.md
```
Expected: `task_type: writing`.

- [ ] **Step 3: Verify Generator did not produce source code**

```bash
ls *.py *.js *.ts 2>/dev/null || echo "no code files — good"
```
Expected: `no code files — good`. The output should be one or more markdown files.

- [ ] **Step 4: Verify Evaluator used rubric-style criteria**

Open `.harness/FEEDBACK.md` and confirm each criterion result quotes or paraphrases specific text from the produced prose (evidence of rubric grading, not command output).

- [ ] **Step 5: Tear down**

```bash
rm -rf .harness docs/*.md content/*.md 2>/dev/null
```

---

## Risks & Open Questions

- **Prompt drift:** Contracts are enforced by prompt text, not code. The model can still emit malformed frontmatter. Mitigation: smoke tests in Tasks 1.6 and 2.5; if drift is seen in practice, a follow-up could add a `/harness-validate` command that regex-checks the frontmatter.
- **Criteria revision not supported:** Flagged above. A phase whose criteria turn out wrong still requires manual `PLAN.md` edit. Acceptable for v1.
- **`research` citation quality:** The Evaluator asks the model to "open cited sources." In practice, fetching external URLs has latency and rate-limit concerns. If this becomes a problem, constrain `research` tasks to user-supplied source material.
- **`design` without Figma:** The plan treats design artifacts as markdown references to images. Tighter Figma integration (via the figma MCP skills already installed) could be a follow-up but is out of scope here.
- **No versioning of the harness schema itself:** `version: 1` is declared but there is no migration path defined. Acceptable until we ship a v2 schema.

---

## Self-Review

**1. Spec coverage:**
- TODO 1 (define expected outputs per agent) → Tasks 1.1–1.5 cover the five commands; 1.6 validates end-to-end; 1.7 closes the roadmap checkbox.
- TODO 2 (support variety of tasks) → Tasks 2.1–2.3 cover Planner/Generator/Evaluator; 2.4 documents; 2.5 validates.

**2. Placeholder scan:** No TBDs, no "implement later", no "similar to Task N", no references to undefined types. Every step names exact file paths and shows exact text to insert.

**3. Type/vocabulary consistency:**
- `harness_artifact`, `verdict`, `task_type` enums defined once in the top-matter "Controlled vocabulary" table and referenced consistently in all tasks.
- `phases_complete` (list), `phase_count` (int), `phase_id` (int), `current_phase` (int), `iteration` (int) — spellings consistent across Tasks 1.1–1.5 and 2.1–2.4.
- Verified Task 1.4 matches Task 1.3's `verdict` vocabulary.
