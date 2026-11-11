---
name: plan
description: Plan the next roadmap phase - settle the open decisions with you, then write the phase plan for approval.
argument-hint: "[phase number]"
disable-model-invocation: true
---

# Plan a phase

Phase: $ARGUMENTS, or else the first unfinished phase in
`.planning/ROADMAP.md`. If `.planning/phase-NN-*.md` already exists for it,
revise that file instead of starting again.

## 1. Ground it

Read `.planning/PROJECT.md`, the phase's roadmap entry, and the code the phase
will touch. Use an Explore agent when that means sweeping an area you have not
read; otherwise read it directly. Where the phase leans on a library or API
whose current behaviour you are not sure of, check its documentation instead
of trusting memory.

`PROJECT.md`'s decisions and findings are settled; build on them. What you
establish now goes into the plan's `## Findings`, so that the build does not
repeat the work: `Verified: <fact> - <command and result, or source and
version>`, or `Matters: <detail the build must respect> - <why>`.

## 2. Settle the gray areas

List the choices that a reasonable person could make differently and that
change what gets built: behaviour, interfaces, the edges of scope, failure
handling. Ask about those in batches, each with your recommendation and its
trade-off. Skip whatever the code, `PROJECT.md` or convention already decides.
If an answer changes what done means, update the phase's `Done when` lines in
the roadmap.

## 3. Write `.planning/phase-NN-<slug>.md`

```markdown
# Phase N: <Name>

Base:

## Done when
- <check, as in the roadmap>

## Decisions
- <what was decided with the user> - <why>

## Tasks
- [ ] 1. <outcome> - <files>; <what it provides to later tasks>; <how it is verified>

## Findings
- <Verified|Matters>: <what was established while planning> - <basis>
```

`NN` is the phase number with two digits. Leave `Base:` empty; the build fills
it in. Only task lines use checkboxes; the session-start status counts them.

A plan records the decisions the implementer could not make alone: which
files, the names and signatures that tasks share, exact values, the order. It
holds no code bodies and nothing the project's `CLAUDE.md` already says.

- Task 1 turns the `Done when` checks into failing tests in the project's own suite. For a check that cannot be automated, say how it will be shown by hand.
- Every later task ends in something testable and is one commit.
- Three to eight tasks. If the phase needs more, or will not fit one session, split it in the roadmap and plan the first part.

## 4. Approve

Summarise the plan in a few lines and point to the file. Revise it until it is
approved, then commit it. Do not start building: suggest `/clear` and then
`/workflows:build`, so that the build starts from the plan and not from this
conversation.
