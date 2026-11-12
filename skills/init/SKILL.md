---
name: init
description: Start managing a project - interview, then write .planning/PROJECT.md and ROADMAP.md. Also revises an existing roadmap.
argument-hint: "[the idea, or a change to the roadmap]"
disable-model-invocation: true
---

# Start or revise a roadmap

Request: $ARGUMENTS

If `.planning/ROADMAP.md` exists, this is a revision: apply the request to the
open phases and the backlog (add, split, reorder, drop), leave finished phases
alone, show the result, and commit it on the current branch once approved. A
phase that has a `.planning/phase-*.md` file keeps its number: the file and
its branch are named after it. Otherwise:

## 1. Learn what exists

Read `CLAUDE.md` and the README. They own the layout, the commands and the
verification gate; `.planning/` never restates them.

If the repository holds real code that those files do not explain, have an
Explore agent map it and report conclusions only: entry points, what each
top-level module is responsible for, how it is tested, what looks fragile.

## 2. Interview

You need: what is being built and for whom, what success looks like, what is
out of scope, and the hard constraints (platforms, dependencies, performance,
compatibility, dates). Take what the request and the repository already
answer. Ask for the rest in batches, each question with your recommended
answer, and push back on vague answers. Stop when you could write a check for
every phase.

## 3. Write

`.planning/PROJECT.md`. Everything above `## Decisions` stays under a page; the
two logs below it grow by one line per entry, and a line that turns out wrong
is rewritten, not contradicted by a new one:

```markdown
# <project>

<What it is, who it is for and why, in two or three sentences.>

## Success
- <observable outcome>

## Out of scope
- <what we are not doing> - <why>

## Constraints
- <hard limit>

## Codebase
<Existing code only: what the map found that CLAUDE.md does not say.>

## Decisions
- <YYYY-MM-DD> <decision> - <why>

## Findings
- <YYYY-MM-DD> <Verified|Invalidated|Matters>: <fact> - <how it was established>
```

Findings are facts that took work to establish: a command's result, a source
and its version, an assumption that proved false, a detail later changes must
respect. Record what the interview and the codebase map established.

`.planning/ROADMAP.md`:

```markdown
# Roadmap

- [ ] 1. <Name> - <what someone can do once it is done>
  - Done when: <observable check>
  - Done when: <observable check>
- [ ] 2. <Name> - <goal>

## Backlog
- <idea not yet scheduled>
```

Keep phase lines in exactly that shape; the session-start status reads them.

- A phase is a vertical slice: it runs end to end and can be demonstrated. It is not a layer.
- A phase is small enough to build and review in one session. Put the riskiest and most depended-on first.
- Two to four `Done when` checks per phase, stated as behaviour (a command and its output, a request and its response), never as tasks.
- Detail the next two phases. Later ones can be a name and a goal; planning sharpens them.

## 4. Approve and commit

Show the roadmap and revise it until it is approved, then commit `.planning/`
on the current branch.
If the repository has no commits yet, commit the existing tree first, as its
own commit, so that phases have a base. If this is not a git repository, ask
before running `git init`.

Next: `/workflow:plan`.
