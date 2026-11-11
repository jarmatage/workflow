#!/bin/sh
# SessionStart hook: print where a managed project stands, so a new, resumed,
# cleared or compacted session can continue without being told.
# Prints nothing unless .planning/ROADMAP.md exists, and never fails a session.
#
# It relies on three conventions that the skills write:
#   ROADMAP.md      - [ ] 2. Name - goal     a phase, at column 0
#   phase-NN-*.md   - [ ] 3. outcome ...     a task; only tasks use checkboxes
#   phase-02-cli.md is built on the branch phase/02-cli, and its `Base:` line
#                   is filled in when the build starts
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
road=.planning/ROADMAP.md
[ -f "$road" ] || exit 0

say() { printf '[workflows] %s\n' "$*"; }
count() { grep -cE "$1" "$2" 2>/dev/null; }
# Shown whenever work remains, so that a session that never invokes a skill
# still knows where earlier conclusions are before it repeats the work.
settled="Settled decisions and findings: .planning/PROJECT.md. Check it before re-deciding or re-verifying."

in_git=""
current=""
if git rev-parse --git-dir >/dev/null 2>&1; then
  in_git=1
  current=$(git branch --show-current 2>/dev/null)
fi

total=$(count '^- \[[ xX]\] [0-9]+\. ' "$road")
closed=$(count '^- \[[xX]\] [0-9]+\. ' "$road")

set -- .planning/phase-*.md
if [ ! -f "$1" ]; then
  next=$(sed -n '/^- \[ \] \([0-9][0-9]*\. \)/{s//\1/p;q;}' "$road" | cut -c1-160)
  if [ -n "$next" ]; then
    say "$closed/$total phases done (.planning/ROADMAP.md). Next: $next"
    say "$settled"
    say "It has no plan yet: /workflows:plan"
  elif [ "$total" -gt 0 ]; then
    backlog=$(awk '/^## Backlog/{f=1;next} /^## /{f=0} f&&/^- /{n++} END{print n+0}' "$road")
    say "All $total phases in .planning/ROADMAP.md are done; $backlog backlog items. Add phases with /workflows:init."
  else
    say ".planning/ROADMAP.md has no phase lines of the form '- [ ] 1. Name - goal'."
  fi
  case "$current" in
    phase/*) say "Still on the finished phase's branch '$current': merge it before planning the next phase." ;;
  esac
  exit 0
fi

plan=$1
# The title and the task are clipped to keep the whole status inside its budget.
title=$(sed -n '1s/^# *//p' "$plan" | cut -c1-60)
tasks=$(count '^- \[[ xX]\] ' "$plan")
ticked=$(count '^- \[[xX]\] ' "$plan")
next=$(sed -n '/^- \[ \] /{s///p;q;}' "$plan" | cut -c1-100)
base=$(sed -n 's/^Base: *//p' "$plan" | head -n 1)
stem=${plan##*/phase-}
branch=phase/${stem%.md}

# The phase's branch exists and this is not it: the phase file here is the copy
# from before the build started, so its ticks and `Base:` say nothing.
elsewhere=""
if [ -n "$in_git" ] && [ "$current" != "$branch" ] && git show-ref --verify --quiet "refs/heads/$branch"; then
  if ! git cat-file -e "$branch:./$plan" 2>/dev/null; then
    say "$title was built and closed out on the branch '$branch', which is not merged here: merge it before going on."
    exit 0
  fi
  elsewhere=1
fi

say "$closed/$total phases done (.planning/ROADMAP.md). Active: $title, plan in $plan"
[ $# -gt 1 ] && say "$# phase files in .planning/, but only one phase may be open; showing the first."
say "$settled"
if [ -n "$elsewhere" ]; then
  say "This phase is being built on the branch '$branch', not here: its progress is there."
elif [ -z "$base" ]; then
  say "Planned, not started ($tasks tasks)."
elif [ -n "$next" ]; then
  say "$ticked/$tasks tasks done. Next: $next"
else
  say "All $tasks tasks ticked; review and close-out remain."
fi

if [ -n "$in_git" ]; then
  dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  [ "$dirty" -gt 0 ] && say "$dirty uncommitted paths."
fi
if grep -q '^## Handoff' "$plan"; then
  say "The plan ends with a Handoff section from the last session: read it first."
fi
say "Continue: /workflows:build"
exit 0
