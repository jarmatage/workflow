---
name: pause
description: Stop mid-phase so that a fresh session can continue - records what the plan and git do not already say.
disable-model-invocation: true
---

# Pause the active phase

If there is no `.planning/phase-*.md`, nothing is in progress and there is
nothing to hand off; say so.

Otherwise bring `## Findings` in that file up to date first, dead ends
included: the handoff is deleted when work resumes, the findings are kept.

Then add `## Handoff` at the end of the file, replacing one that is already
there, with only what the task ticks, the findings and the git history do not
already say:

- the task in progress and how far it got
- the next concrete step
- questions waiting on the user

Commit the phase file by itself. Leave half-finished code uncommitted in the
working tree and name those files in the handoff. If a stop hook then reports
the project's gate failing on that half-finished work, answer that the pause
is deliberate instead of starting to fix it.

The next session's status line points at the handoff, and `/workflow:build`
reads it and removes it.
