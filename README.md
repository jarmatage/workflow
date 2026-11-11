# workflows

A Claude Code plugin for lightweight project management: a roadmap, one plan
per phase, inline builds that end in a fresh-context review, and state kept in
a few small files so that any new session can pick the work up.

It is built for current frontier models. It adds no instructions to a session
until you invoke it, and it leaves verification, formatting and code
navigation to the project.

## Use

```
/plugin marketplace add <path-or-git-url-of-this-repository>
/plugin install workflows@workflows
```

| Command | What it does |
| --- | --- |
| `/workflows:init [idea]` | Interviews you, then writes the project brief and a roadmap of phases. On an existing codebase it maps the code first. Run it again later to revise the roadmap. |
| `/workflows:plan [phase]` | Settles the open decisions for the next phase with you, then writes its plan and waits for approval. |
| `/workflows:build` | Builds the planned phase task by task on its own branch, has a fresh-context agent review it, and closes it out. Also resumes a phase in progress. |
| `/workflows:pause` | Records what a later session could not work out from the plan and git. |

The loop is `plan`, `/clear`, `build`, `/clear`, repeat. You approve each phase
plan; the build then runs to the end of the phase without checking in.

Small changes do not need any of this. Ask for them directly.

## What it keeps

Everything lives in `.planning/`, committed with the code:

| File | Holds |
| --- | --- |
| `PROJECT.md` | What is being built and why, what is out of scope, constraints, and two logs: decisions and findings. |
| `ROADMAP.md` | The phases in order, each with two to four observable `Done when` checks, and a backlog. This is the only record of progress. |
| `phase-NN-<slug>.md` | The plan for the phase being worked on: decisions, tasks, and the findings made while planning and building it. |

A phase file exists only while its phase is open. When the phase closes, a few
`As built` lines go into the roadmap, lasting decisions and findings go into
`PROJECT.md`, and the file is deleted. Git keeps the full plan.

## What a later session can rely on

The point of the files is that no session has to repeat work an earlier one
did. Each thing a session needs to know has one home:

| Question | Answered by |
| --- | --- |
| What is the project trying to achieve? | `PROJECT.md`: summary, Success, Out of scope |
| What has been decided? | `PROJECT.md` Decisions, each with its reason |
| Which implementation details matter? | `Matters:` findings |
| What has been verified? | `Verified:` findings, plus the phase checks kept as tests |
| What remains incomplete? | Unticked phases and tasks, deferred items in `As built`, the Backlog |
| Which assumptions were invalidated? | `Invalidated:` findings; the wrong line is rewritten, not contradicted |

Findings are written while the work happens, one line each, and every line
carries its basis so that it can be trusted without redoing the work:

```
- Decided: one exit code for every failure - simplest for scripts - phase 2 may want to continue past a bad file
- Verified: str.split() treats U+00A0 as whitespace - `len('a b'.split())` is 2 on Python 3.14.4
- Invalidated: PROJECT.md says counts match `wc -w` - they differ on 0x1C-0x1F - `printf 'a\x1cb' | wc -w` is 1
- Matters: tests import the module from the repository root - run them from there
```

Dead ends are findings too. The build reads `PROJECT.md` before it starts, the
reviewer tries to falsify `Verified` lines, and the session-start status tells
every session where the settled conclusions are.

If you settle something outside the workflow, ask Claude to record it in
`PROJECT.md` in the same form.

## Moving between sessions

A `SessionStart` hook prints the project's position at the start of every
session, including after `/clear` and after compaction:

```
[workflows] 1/3 phases done (.planning/ROADMAP.md). Active: Phase 2: CLI, plan in .planning/phase-02-cli.md
[workflows] Settled decisions and findings: .planning/PROJECT.md. Check it before re-deciding or re-verifying.
[workflows] 1/3 tasks done. Next: 2. Argument parser - src/tool/cli.py; provides main(argv) -> int
[workflows] 1 uncommitted paths.
[workflows] Continue: /workflows:build
```

It prints nothing in a project without `.planning/ROADMAP.md`.

There is no separate handoff step in the normal case. Each task is ticked in
the phase file in the same commit as its code, so the file is always current.
`/workflows:build` in a new session continues from the first unticked task.
`/workflows:pause` is for stopping in the middle of a task: it brings the
findings up to date and notes the next step.

## How a phase is built

- **One branch per phase**, named after the phase file, with one commit per task. The plugin never merges or pushes without asking.
- **Inline.** The session that reads the plan implements all of it. Subagents are used only to explore unfamiliar code and for the review.
- **Checks first.** The first task of every plan turns the phase's `Done when` checks into failing tests in the project's own suite, so the project's gate enforces them. The gate is therefore red until the last task, and the build is told to expect that.
- **No check-ins.** When the plan is wrong or silent, the build decides and logs the decision with its reason. It stops only for destructive, security-sensitive or outward-facing actions, or a plan that needs redoing.
- **One review.** At the end, a single fresh-context agent checks every `Done when` item by running it, looks for bugs in the branch diff, and tries to falsify the `Verified` findings.
- **Learning.** At close-out it proposes at most three gotchas for the project's `CLAUDE.md`, and adds only those you accept.

## With project-templates

The plugin is meant to sit on top of projects generated by
[project-templates](https://github.com/jarmatage/project-templates) and repeats nothing they provide:

| Concern | Owner |
| --- | --- |
| Commands, layout, test rules | The project's `CLAUDE.md` |
| Formatting after each edit, `just check` on stop | The project's hooks |
| Symbol navigation | The project's language-server plugin |
| What to build, in what order, and where the work stands | This plugin |

The skills refer to "the project's gate" and "the narrowest command in the
project's `CLAUDE.md`", so they also work in projects that were not generated
from the templates, provided their `CLAUDE.md` names those commands.

State is kept in `.planning/` and not `docs/` because the Python templates
build everything under `docs/` into the documentation site.

One interaction to know about: the templates' stop hook runs `just check`
whenever the tree has changed. If you pause with half-finished code that fails
the gate, the hook hands the failure back up to three times before giving up.

## What it costs in context

| When | Cost |
| --- | --- |
| Every session, unmanaged project | Nothing. The skills are slash-only, so not even their descriptions are loaded. |
| Every session, managed project | The status lines: under 700 bytes. |
| Invoking a skill | That skill's text: 1.1 to 4 KB each, 11.2 KB for all four. |

`just test` enforces these budgets: 700 bytes for the status, 4000 per skill.

## Deliberately absent

Each of these exists in larger workflow systems and was left out on purpose.
Add one only when a real project shows the need.

- Always-on instructions, and skills that the model invokes by itself.
- Custom agents. The built-in Explore and general-purpose agents are enough.
- A separate state file, progress metrics, or per-phase research, summary and verification documents.
- Per-task subagents and per-step test-driven checklists.
- Rules about testing, formatting or linting. The project owns those.
- Milestones, parallel worktrees and multi-person handoffs.

Instructions written to compensate for one model generation become overhead
for the next. Reread the four skills after a major model release and delete
what the model no longer needs to be told.

## Develop

```sh
just test       # the hook against throwaway projects, plus the size budgets
just validate   # the plugin and marketplace manifests
just check      # both
just budget     # bytes per skill
```

Try a change without installing: `claude --plugin-dir <this-repository>`.
