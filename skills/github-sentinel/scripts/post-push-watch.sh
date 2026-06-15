#!/bin/bash
# GitHub Sentinel — Post-Push CI Watcher
# Monitors the CI run triggered by a git push.
# Output is visible to Claude Code so it can offer to diagnose and fix failures.
#
# This script is MONITOR-ONLY — it never modifies code or retries CI.
# Use /sentinel fix to act on failures.

set -euo pipefail

# Get repo identity
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
  exit 0
fi

BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ -z "$BRANCH" ]; then
  exit 0
fi

# Brief pause for GitHub to register the push event
sleep 4

# Find the latest workflow run for this branch
RUN_JSON=$(gh run list --repo "$REPO" --branch "$BRANCH" --limit 1 --json databaseId,status,name,event 2>/dev/null || echo "[]")
RUN_ID=$(echo "$RUN_JSON" | jq -r '.[0].databaseId // empty' 2>/dev/null || echo "")
RUN_NAME=$(echo "$RUN_JSON" | jq -r '.[0].name // "CI"' 2>/dev/null || echo "CI")

if [ -z "$RUN_ID" ]; then
  exit 0
fi

STATUS=$(echo "$RUN_JSON" | jq -r '.[0].status // empty' 2>/dev/null || echo "")

# If already completed, check result immediately
if [ "$STATUS" = "completed" ]; then
  CONCLUSION=$(gh run view "$RUN_ID" --repo "$REPO" --json conclusion -q .conclusion 2>/dev/null || echo "")
  if [ "$CONCLUSION" = "success" ]; then
    echo "✅ $RUN_NAME passed for $REPO ($BRANCH)"
    exit 0
  else
    echo ""
    echo "❌ $RUN_NAME FAILED for $REPO ($BRANCH)"
    echo "   Run: https://github.com/$REPO/actions/runs/$RUN_ID"
    echo ""
    echo "Failed step logs (last 40 lines):"
    gh run view "$RUN_ID" --repo "$REPO" --log-failed 2>/dev/null | tail -40
    echo ""
    echo "💡 Use /sentinel fix https://github.com/$REPO/actions/runs/$RUN_ID to diagnose and repair."
    exit 0
  fi
fi

# Watch the run until completion (timeout: 10 minutes)
echo "⏳ Watching $RUN_NAME run $RUN_ID for $REPO ($BRANCH)..."

if gh run watch "$RUN_ID" --repo "$REPO" --exit-status 2>/dev/null; then
  echo "✅ $RUN_NAME passed for $REPO ($BRANCH)"
else
  echo ""
  echo "❌ $RUN_NAME FAILED for $REPO ($BRANCH)"
  echo "   Run: https://github.com/$REPO/actions/runs/$RUN_ID"
  echo ""
  echo "Failed step logs (last 40 lines):"
  gh run view "$RUN_ID" --repo "$REPO" --log-failed 2>/dev/null | tail -40
  echo ""
  echo "💡 Use /sentinel fix https://github.com/$REPO/actions/runs/$RUN_ID to diagnose and repair."
fi
