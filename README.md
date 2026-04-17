# Roadmap:

- [x] Define the expected outputs for every step/agent (YAML frontmatter contracts — see `.claude/commands/*`)
- [] Support variety of tasks. Currently, only general coding tasks

# Harness — Three-Agent Build System for Claude Code

A lightweight implementation of the [harness design pattern](https://www.anthropic.com/engineering/harness-design-long-running-apps) for Claude Code. Three specialized agents — Planner, Generator, and Evaluator — collaborate through file-based handoffs to build software iteratively with quality gates.

## Why use this?

Single-agent coding sessions degrade over long tasks due to two problems:

1. **Context rot** — the model loses coherence as the context window fills up
2. **Self-evaluation bias** — agents praise their own mediocre work

The harness pattern solves both by separating planning, implementation, and evaluation into distinct roles that communicate through structured files rather than a single conversation.

## Setup

Copy the `.claude/commands/` folder into your project:

```bash
cp -r .claude/commands/ /path/to/your-project/.claude/commands/
```

That's it. The commands are now available in Claude Code when you're in that project.

## Commands

### `/harness-run` — Full automated pipeline (recommended)

Run the entire Planner → Generator → Evaluator loop automatically:

```
/harness-run Build a CLI tool that converts CSV files to JSON with filtering and sorting options
```

This will:
- Plan the project into phases with testable criteria
- Implement each phase
- Evaluate each phase by actually running the code
- Iterate up to 3 times per phase if issues are found
- Print a final summary

### `/harness-plan` — Plan only

Generate a spec without implementing anything:

```
/harness-plan Build a REST API for a todo app with SQLite storage
```

Review the plan in `.harness/PLAN.md` before proceeding.

### `/harness-generate` — Implement a phase

Implement the next incomplete phase (or a specific one):

```
/harness-generate
/harness-generate 2
```

### `/harness-evaluate` — Evaluate a phase

Test the most recently completed phase (or a specific one):

```
/harness-evaluate
/harness-evaluate 1
```

### `/harness-status` — Check progress

See the current state of the harness run:

```
/harness-status
```

## Manual workflow (step-by-step control)

If you prefer to review between steps:

```
1. /harness-plan Build a markdown blog engine with tags and search
2. Review .harness/PLAN.md — edit if needed
3. /harness-generate 1
4. /harness-evaluate 1
5. If REVISE → /harness-generate 1 (addresses feedback)
6. If APPROVE → /harness-generate 2
7. Repeat until all phases are done
```

## File structure

All harness state lives in `.harness/` at your project root:

```
.harness/
├── PLAN.md       # The spec — phases, scope, acceptance criteria
├── STATE.md      # Progress log — which phases are done, implementation notes
└── FEEDBACK.md   # Latest evaluation — pass/fail per criterion, issues
```

These files ARE the communication channel between agents. The Generator reads the plan and feedback; the Evaluator reads the plan and state. No shared conversation needed.

## Iteration limits

Each phase can be revised up to 3 times. If it still fails after 3 rounds, the harness stops and asks you to intervene. This prevents burning tokens on diminishing returns.

## Adapting the harness

The article's key insight: *every harness component encodes an assumption about what the model can't do alone.* As models improve, revisit your harness:

- If the model plans well on its own → simplify or remove the Planner
- If evaluation is always passing first try → reduce iteration caps
- If tasks are simple enough → use `/harness-plan` + `/harness-generate` without the Evaluator
- For subjective tasks (design, UX) → add screenshot-based evaluation criteria

## Credits

Based on [Harness Design for Long-Running Application Development](https://www.anthropic.com/engineering/harness-design-long-running-apps) by Prithvi Rajasekaran at Anthropic.
