#!/bin/sh
# Tests for hooks/state.sh and the size budgets. Run with `just test`.
# Each case builds a throwaway project, runs the hook the way Claude Code does
# (CLAUDE_PROJECT_DIR set, output on stdout) and checks what it printed.
root=$(cd "$(dirname "$0")/.." && pwd)
hook="$root/hooks/state.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0
n=0

project() { # project <name> [git]: make an empty project and cd into it
  dir="$tmp/$1"
  mkdir -p "$dir/.planning"
  cd "$dir" || exit 1
  if [ "${2:-}" = git ]; then
    git init -q -b main .
    git config user.email test@example.com
    git config user.name test
    git commit -q --allow-empty -m base
  fi
}
run() { out=$(CLAUDE_PROJECT_DIR="$PWD" sh "$hook" 2>&1); status=$?; }
ok() { n=$((n + 1)); }
fail() { n=$((n + 1)); fails=$((fails + 1)); printf 'FAIL %s: %s\n--- output\n%s\n---\n' "$case_name" "$1" "$out"; }
has() { case "$out" in *"$1"*) ok ;; *) fail "expected: $1" ;; esac; }
lacks() { case "$out" in *"$1"*) fail "unexpected: $1" ;; *) ok ;; esac; }
exits0() { if [ "$status" -eq 0 ]; then ok; else fail "exit status $status"; fi; }

roadmap() {
  cat >.planning/ROADMAP.md <<'EOF'
# Roadmap

- [x] 1. Parser - read a config file
  As built: parses TOML into a Config.
- [ ] 2. CLI - run it from a shell
  - Done when: `tool --help` exits 0
  - Done when: `tool run x.toml` prints the result
- [ ] 3. Docs - explain it

## Backlog
- colour output
- shell completion
EOF
}
phase() { # phase <base> <tick1> <tick2> <tick3>
  cat >.planning/phase-02-cli.md <<EOF
# Phase 2: CLI

Base: $1

## Done when
- \`tool --help\` exits 0

## Decisions
- argparse, no dependency - keeps install small

## Tasks
- [$2] 1. Failing tests for the two checks - tests/test_cli.py
- [$3] 2. Argument parser - src/tool/cli.py; provides main(argv) -> int
- [$4] 3. Wire the run command - src/tool/cli.py; verified by test_cli.py

## Findings
EOF
}

case_name="unmanaged project is silent"
project plain && rmdir .planning
run; exits0
[ -z "$out" ] && ok || fail "expected no output"

case_name="roadmap without a plan"
project noplan git && roadmap
run; exits0
has "1/3 phases done"
has "Next: 2. CLI - run it from a shell"
has "Settled decisions and findings: .planning/PROJECT.md"
has "/workflows:plan"
lacks "Done when"
lacks "/workflows:build"

case_name="works outside git"
project nogit && roadmap && phase "" " " " " " "
run; exits0
has "Active: Phase 2: CLI, plan in .planning/phase-02-cli.md"
has "Planned, not started (3 tasks)"
lacks "uncommitted"

case_name="planned, not started"
project planned git && roadmap && phase "" " " " " " "
git add -A && git commit -q -m plan
run; exits0
has "Planned, not started (3 tasks)"
has "Continue: /workflows:build"
lacks "uncommitted"
lacks "stale"

case_name="mid-phase on the phase branch"
project mid git && roadmap
git checkout -q -b phase/02-cli
phase abc1234 x " " " "
git add -A && git commit -q -m "task 1"
echo wip >scratch.py
run; exits0
has "1/3 tasks done. Next: 2. Argument parser"
has "Settled decisions and findings: .planning/PROJECT.md"
has "1 uncommitted paths"
lacks "stale"
lacks "Handoff"

case_name="handoff is announced"
printf '\n## Handoff\n- parser half written in src/tool/cli.py\n' >>.planning/phase-02-cli.md
run; exits0
has "Handoff section from the last session"
has "2 uncommitted paths"

case_name="on another branch while the phase branch exists"
project stale git && roadmap && phase "" " " " " " "
git add -A && git commit -q -m plan
git branch phase/02-cli
run; exits0
has "being built on the branch 'phase/02-cli', not here"
has "Continue: /workflows:build"
lacks "Planned, not started"

case_name="all tasks ticked"
project ticked git && roadmap
git checkout -q -b phase/02-cli
phase abc1234 x x x
git add -A && git commit -q -m "task 3"
run; exits0
has "All 3 tasks ticked; review and close-out remain."

case_name="closed out but not merged"
project unmerged git && roadmap
git checkout -q -b phase/02-cli
git add -A && git commit -q -m "close out"
run; exits0
has "Still on the finished phase's branch 'phase/02-cli'"

case_name="closed out on its branch, back on the unmerged base"
project unmerged-base git && roadmap && phase "" " " " " " "
git add -A && git commit -q -m plan
git checkout -q -b phase/02-cli
git rm -q .planning/phase-02-cli.md && git commit -q -m "close out"
git checkout -q main
run; exits0
has "Phase 2: CLI was built and closed out on the branch 'phase/02-cli', which is not merged here"
lacks "Planned, not started"
lacks "/workflows:build"

case_name="every phase done"
project alldone git
printf -- '- [x] 1. Parser - read a config file\n- [X] 2. CLI - run it\n\n## Backlog\n- colour output\n- completion\n\n## Notes\n- not backlog\n' >.planning/ROADMAP.md
run; exits0
has "All 2 phases in .planning/ROADMAP.md are done; 2 backlog items."
lacks "Settled decisions"

case_name="roadmap in the wrong shape"
project badshape
printf '# Roadmap\n\n## Phase 1: Parser\n' >.planning/ROADMAP.md
run; exits0
has "has no phase lines of the form"

case_name="two phase files"
project two && roadmap && phase "" " " " " " "
cp .planning/phase-02-cli.md .planning/phase-03-docs.md
run; exits0
has "Active: Phase 2: CLI, plan in .planning/phase-02-cli.md"
has "2 phase files in .planning/, but only one phase may be open"

# Budgets: the point of this plugin is to stay small. A session pays for the
# hook's output every time it starts, and for a skill each time it is invoked.
case_name="status output budget"
project worst git && roadmap
long=$(printf '%0200d' 0)
slug=a-phase-slug-of-thirty-chars-x
git checkout -q -b "phase/02-$slug"
phase abc1234 x " " " "
{
  echo "# Phase 2: $long"
  sed -e 1d -e "s/^- \\[ \\] 2\\. .*/- [ ] 2. $long/" .planning/phase-02-cli.md
  printf '\n## Handoff\n- half written\n'
} >".planning/phase-02-$slug.md"
mv .planning/phase-02-cli.md .planning/phase-03-docs.md
run; exits0
has "1/3 tasks done. Next: 2. 000"
has "2 phase files"
has "uncommitted paths"
has "Handoff section"
bytes=$(printf '%s' "$out" | wc -c | tr -d ' ')
[ "$bytes" -le 700 ] && ok || fail "status is $bytes bytes, budget 700"

for skill in "$root"/skills/*/SKILL.md; do
  case_name="skill budget: ${skill#"$root"/}"
  out=""
  bytes=$(wc -c <"$skill" | tr -d ' ')
  [ "$bytes" -le 4000 ] && ok || fail "$bytes bytes, budget 4000"
  grep -q '^disable-model-invocation: true$' "$skill" && ok || fail "must be slash-only (disable-model-invocation: true)"
done

if [ "$fails" -eq 0 ]; then
  echo "ok: $n checks"
else
  echo "$fails of $n checks failed"
  exit 1
fi
