#!/bin/bash
# Install cc-harness commands into your project
# Usage: curl -fsSL https://raw.githubusercontent.com/YOUR_USER/cc-harness/main/setup.sh | bash

set -e

TARGET=".claude/commands"
mkdir -p "$TARGET"

COMMANDS="harness-plan harness-generate harness-evaluate harness-run harness-status"

echo "Installing cc-harness commands..."
for cmd in $COMMANDS; do
  echo "  → $cmd"
  cp "$(dirname "$0")/.claude/commands/${cmd}.md" "$TARGET/${cmd}.md" 2>/dev/null || \
    echo "    (skipped — run from the cc-harness repo root)"
done

echo ""
echo "Done! Commands available in Claude Code:"
echo "  /harness-run     — Full automated pipeline"
echo "  /harness-plan    — Plan only"
echo "  /harness-generate — Implement a phase"
echo "  /harness-evaluate — Evaluate a phase"
echo "  /harness-status  — Check progress"
