#!/usr/bin/env bash
# claude-loadout installer
# Installs original skills from this repo + upstream skills from their sources.
# Usage: ./install.sh [--originals-only] [--upstream-only]

set -e

SKILLS_DIR="$(cd "$(dirname "$0")/skills" && pwd)"
CLAUDE_SKILLS="$HOME/.claude/skills"
ORIGINALS_ONLY=false
UPSTREAM_ONLY=false

for arg in "$@"; do
  case $arg in
    --originals-only) ORIGINALS_ONLY=true ;;
    --upstream-only)  UPSTREAM_ONLY=true ;;
  esac
done

# ── Original skills (from this repo) ──────────────────────────────────────────
if [ "$UPSTREAM_ONLY" = false ]; then
  echo "Installing original skills..."
  mkdir -p "$CLAUDE_SKILLS"
  for skill_dir in "$SKILLS_DIR"/*/; do
    skill_name=$(basename "$skill_dir")
    dest="$CLAUDE_SKILLS/$skill_name"
    if [ -d "$dest" ]; then
      echo "  ↺  $skill_name (updating)"
    else
      echo "  +  $skill_name"
    fi
    cp -r "$skill_dir" "$dest"
  done
  echo ""
fi

# ── Upstream skills (installed via npx skills add) ────────────────────────────
if [ "$ORIGINALS_ONLY" = false ]; then
  echo "Installing upstream skills..."
  npx --yes skills add anthropics/knowledge-work-plugins@brand-voice-enforcement
  npx --yes skills add anthropics/knowledge-work-plugins@ux-copy
  npx --yes skills add resend/email-best-practices@email-best-practices
  npx --yes skills add wshobson/agents@wcag-audit-patterns
  npx --yes skills add daffy0208/ai-dev-standards@design-system-architect
  npx --yes skills add affaan-m/everything-claude-code@security-review
  npx --yes skills add miketromba/skills@legal-tos-privacy
  npx --yes skills add prowler-cloud/prowler@tailwind-4
  npx --yes skills add pbakaus/impeccable@impeccable
  npx --yes skills add benjitaylor/agentation@agentation
  npx --yes skills add thebushidocollective/han@gluestack-accessibility
  npx --yes skills add vercel-labs/agent-skills@vercel-react-best-practices
  npx --yes skills add vercel-labs/agent-skills@vercel-composition-patterns
  npx --yes skills add vercel-labs/agent-skills@vercel-react-native-skills
  npx --yes skills add vercel-labs/agent-skills@web-design-guidelines
  echo ""
fi

echo "Done. Restart Claude Code to load new skills."
