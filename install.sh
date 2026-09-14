#!/usr/bin/env bash
#
# Installs this repo's skills for a target code assistant: copies each
# skills/<name>/ directory (SKILL.md + scripts/) to the target skills
# directory. Installs both skills - conference-notes (full multi-talk site)
# and talk-writeup (single-talk write-up, no site) - since conference-notes
# calls into talk-writeup per talk and expects it installed alongside.
#
# skills/ in this repo stays the single source of truth for editing -
# re-run this script after pulling changes to resync installed copies.
#
# Usage: ./install.sh <target> [dest]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS=(conference-notes talk-writeup)

usage() {
  cat <<'EOF'
Usage: install.sh <target> [dest]

Targets:
  claude-code            ~/.claude/skills
  claude-code-project    <cwd>/.claude/skills
  copilot                ~/.copilot/skills
  copilot-agents         ~/.agents/skills          (shared cross-tool convention)
  copilot-project        <cwd>/.agents/skills       (Copilot CLI monorepo discovery)
  custom <dest>          any directory you provide

Examples:
  ./install.sh claude-code
  ./install.sh copilot
  ./install.sh custom ~/some/other/skills/dir

Alternatively, skip this script entirely:
  gh skill install <owner>/conference-notes conference-notes
  npx skills add <owner>/conference-notes
EOF
}

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

target="$1"
dest=""

case "$target" in
  claude-code)          dest="$HOME/.claude/skills" ;;
  claude-code-project)  dest="$PWD/.claude/skills" ;;
  copilot)              dest="$HOME/.copilot/skills" ;;
  copilot-agents)       dest="$HOME/.agents/skills" ;;
  copilot-project)      dest="$PWD/.agents/skills" ;;
  custom)
    if [ $# -lt 2 ]; then
      echo "error: 'custom' target requires a destination path" >&2
      usage
      exit 1
    fi
    dest="$2"
    ;;
  -h|--help|help)
    usage
    exit 0
    ;;
  *)
    echo "error: unknown target '$target'" >&2
    usage
    exit 1
    ;;
esac

if [ -z "$dest" ] || [ "$dest" = "/" ]; then
  echo "error: refusing to install to an empty path or '/'" >&2
  exit 1
fi

echo "Installing to: $dest"
mkdir -p "$dest"

for SKILL in "${SKILLS[@]}"; do
  src="$SCRIPT_DIR/skills/$SKILL"
  if [ ! -d "$src" ]; then
    echo "error: $src not found - run from the conference-notes repo root" >&2
    exit 1
  fi

  target_dir="$dest/$SKILL"
  echo "  - $SKILL -> $target_dir"
  rm -rf "$target_dir"
  mkdir -p "$target_dir"
  cp -r "$src/." "$target_dir/"
done

echo "Done. Installed: ${SKILLS[*]}"
