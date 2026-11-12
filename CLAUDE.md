# workflow

A Claude Code plugin: four slash-only skills and one `SessionStart` hook that
manage a project through files in its `.planning/` directory.

## Layout

- `skills/{init,plan,build,pause}/SKILL.md` - the workflow; each is a prompt that another Claude session reads
- `hooks/state.sh` - prints a managed project's position at session start; `hooks/hooks.json` registers it
- `tests/test.sh` - runs the hook against throwaway projects and enforces the size budgets
- `.claude-plugin/` - plugin and marketplace manifests

## Verification

A change is done when `just check` passes (`just test` and `just validate`).
A change to a skill's wording also needs a real run: start
`claude --plugin-dir .` in a scratch project and invoke the skill.

## Gotchas

- The skills and the hook share a file format: phase lines in `ROADMAP.md`
  (`- [ ] 2. Name - goal`), task lines in the phase file (the only checkboxes
  there), the `Base:` line, and the branch name derived from the phase file's
  name. Change the format in the skill templates, `hooks/state.sh` and
  `tests/test.sh` together.
- The finding prefixes (`Decided`, `Verified`, `Invalidated`, `Matters`) are
  spelled out in `init`, `plan` and `build`. Change them in all three.
- `init` and `plan` say to commit "on the current branch" because Claude Code
  tells a session on the default branch to branch before committing. Without
  those words a real run of `plan` committed the plan to a stray branch, where
  neither `build` nor the hook looks for it.
- Size is the product. Tests fail a skill over 4000 bytes or a status output
  over 700. Before adding a sentence, ask whether a current model would get
  it wrong without being told; if not, leave it out.
- Every skill keeps `disable-model-invocation: true`, so nothing is loaded
  into a session until the user asks.
- Do not restate what a project's own `CLAUDE.md` and hooks provide (commands,
  test rules, formatting, the gate). Refer to them as "the project's gate".
- `hooks/state.sh` is POSIX `sh` with no dependencies beyond git and coreutils,
  and must exit 0 whatever it finds.
