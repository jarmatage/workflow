---
name: build
description: Build the planned phase - every task, one review, close-out. Also resumes a phase in progress.
disable-model-invocation: true
---

# Build the active phase

The active phase is the `.planning/phase-*.md` file. If there is none, stop
and suggest `/workflows:plan`.

## Start or resume

Read `.planning/PROJECT.md` first. Its decisions and findings are settled: do
not work them out again. If one proves wrong, or true only in part, log it as
`Invalidated`.

The phase's branch is named after its file: `phase-02-cli.md` is built on
`phase/02-cli`.

- The branch does not exist: create it from the current commit and record that commit as `Base:`.
- It exists: switch to it. Read `## Handoff` if present, then remove it. Check `git status` and the diff for half-finished work, and continue from the first unticked task.

## Tasks

For each task in order: implement it, verify it with the narrowest command in
the project's `CLAUDE.md` that covers it, tick it in the phase file, and commit
the code and the phase file together.

Task 1's tests stay red until later tasks pass them; never skip or weaken
them to quiet the gate.

Work through the whole phase without checking in. When the plan is wrong or
silent, decide and carry on.

Under `## Findings`, log as you go whatever a later session would otherwise
have to work out again. One line each, with enough basis to be trusted without
redoing the work:

- `Decided: <choice the plan left open or got wrong> - <why> - <what it costs if wrong>`
- `Verified: <fact> - <command and result, or source and version>`
- `Invalidated: <what the plan or PROJECT.md assumed> - <what is true instead> - <how you found out>`
- `Matters: <detail a later change must respect> - <why>`

Dead ends count. Leave out what the diff already shows.

A decision the user makes mid-build goes under `## Decisions`. An idea or a
problem outside this phase goes to the roadmap's Backlog, not into the code.

Stop and ask only before something destructive, irreversible or
security-sensitive, anything with effects outside this repository (push,
publish, merge), or when the plan is wrong enough to need replanning.

## Review

When every task is ticked, run the project's full gate. Then give one
general-purpose agent this brief:

> Review a finished phase. Report; do not edit. Read `<phase file>` for its
> `Done when` checks, decisions and findings, and read the change with
> `git diff <Base>...HEAD`.
> 1. For each `Done when` check: met or not met, with evidence from running it, not from reading test names.
> 2. Bugs, regressions and inputs a user would plausibly hit that the changed code mishandles, most severe first, each with a concrete failing scenario.
> 3. Any `Verified` finding you can show to be false.
>
> Leave out style, formatting and lint; the project's gate owns those.

Fix what you confirm and log what it taught you. For each point you reject,
keep one line of reasoning for the report. Review again only if a fix changed
the design.

## Close out

1. In `.planning/ROADMAP.md`, tick the phase and replace its `Done when` lines with an indented `As built:` note of three to five lines: what now exists, where it departs from the plan, what was deferred. Deferred items also go to the Backlog.
2. Carry what outlives the phase into `.planning/PROJECT.md`, keeping each line's basis: the phase's decisions and `Decided` lines into `## Decisions`, the other findings into `## Findings`. Where one contradicts or narrows a line already there, including a decision's stated reason, rewrite that line so the file never disagrees with itself.
3. Delete the phase file and commit.
4. Report what was built, what you decided, and what you did about each review point.
5. Propose at most three gotchas for the project's `CLAUDE.md`: things that cost time here and that no tool enforces. Add only those the user accepts.
6. Ask whether to merge the branch.

Next: `/clear`, then `/workflows:plan`.
