---
name: dev
description: "The base dev flow: analyze -> implement -> review, one folder per task, an owner gate at every handover"
sequence: [dev-analyze, dev-implement, dev-review]
---

# FLOW-dev — the base flow

Three skills, one task folder, three artifacts. Each stage READS the previous stage's
artifact and WRITES its own; between them stands a gate only a human closes. The flow is
the discipline of not skipping the writing — and of not letting a stage start from a
conversation that the next session cannot see.

## Using it

```
dev-analyze  <TASK> [description…]     # stage 1 — what is wanted, what it touches
dev-implement <TASK>                    # stage 2 — the smallest sufficient change
dev-review   <TASK>                     # stage 3 — independent verdict
```

`<TASK>` is the name this work is known by and the folder every stage uses. Use the
tracker id when there is one (`ABC-142`), otherwise a short kebab slug that will still
make sense in a month (`events-filter-by-city`). Allowed: letters, digits, `.`, `_`, `-` —
no slashes or spaces, because the name becomes a path.

The **description** is passed once, to stage 1, in your own words:

```
dev-analyze events-filter-by-city  visitors should be able to filter the events list by city;
                                   the filter must survive a page reload
```

Stages 2 and 3 need no description — everything they need is in the folder. If you invoke
a stage without `<TASK>`, it asks; it never guesses which task you meant.

## The artifact chain

| Stage | Skill | Reads | Writes |
|---|---|---|---|
| 1 | `dev-analyze` | your description + the code | `memory/spec/<TASK>/analysis.md` |
| 2 | `dev-implement` | `analysis.md` (approved) | `memory/spec/<TASK>/implementation.md` + the working-tree change |
| 3 | `dev-review` | `analysis.md`, `implementation.md`, the diff | `memory/spec/<TASK>/review.md` |

```
memory/spec/<TASK>/
  analysis.md         # what is wanted, what it touches, what could break, how to verify
  implementation.md   # what changed and the evidence it works
  review.md           # verdict + findings by severity
```

Stage 1 creates the folder and the empty stubs (idempotent — it never clobbers a file that
has content). `memory/` is instance data: it lives outside the workspace and is never
compiled, overwritten or shipped by an update.

Every artifact opens with the same block, and it is what makes the chain checkable:

```markdown
---
task: <TASK>
stage: analysis | implementation | review
status: draft | approved
---
```

## The gate

**A stage stops when its artifact is written.** It reports in chat, names the file, and
asks. It does not launch the next skill, and the next skill refuses to start on a `draft`
input — that refusal is the gate doing its job, not a malfunction.

The approval lives in the file, not in the chat, because the next session cannot read your
chat: on your explicit word the skill sets `status: approved`. An agent must never approve
its own artifact on the grounds that it looks fine.

| Gate | You are deciding |
|---|---|
| after stage 1 | is this the right problem, in the right place, with the right plan? Cheapest moment to redirect — nothing is written yet |
| after stage 2 | is the change what was agreed, and is the evidence real? |
| after stage 3 | needs-changes → back to stage 2 · approve → you land it (commit/push is yours under the workspace git law) |

Verdict `needs-changes` sends the loop back to `dev-implement <TASK>`: it appends to
`implementation.md` rather than starting over, and `review.md` stays as the record of what
was wrong. Re-review the same way.

## Scale, don't skip

A one-line content fix still runs all three stages — they just get short: three sentences
of analysis, a diff, a verdict. Skipping the analysis on a "trivial" task is how trivial
tasks stop being trivial. What legitimately shrinks is the writing, never the sequence.

Resuming a task after a break: read `memory/spec/<TASK>/` first — the three files plus
their `status:` lines tell you exactly where the work stands, which is the entire reason
they exist.
