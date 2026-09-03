---
name: dev-review
description: 'The REVIEWER — stage 3 of the base flow. Takes the TASK NAME, judges the diff against memory/spec/<TASK>/analysis.md and implementation.md, re-runs the decisive verification itself, and writes review.md with a verdict for the owner. Invoke: dev-review <TASK>.'
argument-hint: '<TASK>'
allowed-tools: [Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion]
metadata:
  taut:
    agents: [dev-reviewer]
---

# dev-review — the reviewer (stage 3)

Independent eyes on the change. Review the DIFF against the TASK — not the diff against
nothing.

| | |
|---|---|
| **Invoke** | `dev-review <TASK>` |
| **Input** | the working-tree diff + `memory/spec/<TASK>/analysis.md` and `implementation.md` |
| **Output** | `memory/spec/<TASK>/review.md`, `status: draft`, verdict approve / needs-changes |
| **Gate** | the owner accepts the verdict — see *The owner gate* below |
| **Next** | needs-changes → `dev-implement <TASK>` again; approve → the owner lands it |

## 0. Entry check

- No `<TASK>` given → ask.
- `implementation.md` missing or empty → **stop**: there is nothing to review yet.
- `implementation.md` still `status: draft` → say so and review anyway if the owner asks,
  but record in the verdict that stage 2 had not passed its gate.
- Read the analysis BEFORE the diff. Judging a change without knowing what was intended
  produces style comments and misses the important finding.

## Process (universal)

1. **Re-derive the intent** from the task and the analysis; then judge whether the diff
   achieves it. A beautiful change to the wrong place is a critical finding.
2. **Correctness first**: edge cases, error paths, concurrency, data shapes at the
   boundaries. Then conventions and clarity. Style-only nits last and marked as such.
3. **Do not trust the implementer's evidence — reproduce it.** Re-run the decisive
   verification yourself (delegate to the `dev-reviewer` subagent when the suite is
   long). The implementation notes say what was run; your job is to check it still
   holds and that the RIGHT things were run.
4. **Check the blast radius**: what else consumes the changed code? Grep for usages the
   diff did not touch; unintended lockfile / config / generated-file changes are
   findings.
5. **Findings, not fixes.** Report by severity (critical / should-fix / nit) with file
   and line; trivial mechanical fixes MAY be applied directly, everything else goes
   back to `dev-implement`. Write the verdict to `memory/spec/<TASK>/review.md`, starting
   with:

   ```markdown
   ---
   task: <TASK>
   stage: review
   status: draft
   verdict: approve | needs-changes
   ---
   ```

## Stack-specific review checks

<!-- stack-node:on -->
**node:** type escapes (`any`, `as`, `@ts-ignore`) introduced by the diff; promise
chains without error handling; unintended dependency or lockfile drift; monorepo edits
that bypass the project graph (deep relative imports across packages).
<!-- stack-node:end -->
<!-- stack-jvm:on -->
**jvm:** nullability at the new boundaries (Kotlin platform types, `Optional` misuse);
resource handling (try-with-resources / `use`); transaction and DI scope of new beans;
tests placed to actually run (right module, right naming convention).
<!-- stack-jvm:end -->
<!-- stack-android:on -->
**android:** check the lifecycle, not just the logic — work started in a composable or an
Activity must survive rotation and stop when the scope dies (collect in
`repeatOnLifecycle`/`collectAsStateWithLifecycle`, cancel coroutines with the right
scope). A `Context` held in a long-lived object is a leak. New permissions in
`AndroidManifest.xml` need the runtime request path too; APIs above `minSdk` need an
explicit gate. Release builds differ from debug — R8/ProGuard rules for anything
reflective (serialization, Room, DI) are part of the change. And ask whether the
instrumented tests were actually RUN: they are the ones CI most often skips.
<!-- stack-android:end -->
<!-- stack-php:on -->
**php:** `declare(strict_types=1)` and parameter/return types on new code; injection
surfaces (raw SQL, unescaped output) in the touched paths; error suppression (`@`)
introduced by the diff; config/DI changes consistent with the framework's conventions.
<!-- stack-php:end -->
<!-- stack-python:on -->
**python:** typing at the new boundaries (`Any`, missing return types, `# type: ignore`
introduced by the diff); mutable default arguments and mutable class-level state;
resources closed (`with` for files and connections) and `async` calls actually awaited;
exception handling that swallows (`except Exception: pass`); manifest and lock changed
together (`pyproject.toml` vs `uv.lock` / `poetry.lock`) or neither; Django: a migration
for every model change, reversible; tests placed where the runner finds them (`tests/`,
`test_*.py`, `conftest.py` fixtures) and not skipped by a stale marker.
<!-- stack-python:end -->

## The owner gate

**STOP here** — the reviewer never lands the change and never re-implements it. Report the
verdict in two sentences with the findings that drive it.

- **needs-changes** → the owner decides; on their word the loop goes back to
  `dev-implement <TASK>`, which appends to `implementation.md` rather than starting over.
  `review.md` stays as the record of what was wrong.
- **approve** → on the owner's explicit acceptance set `status: approved`. Landing the
  change (commit, branch, push) is the owner's act under the workspace git law — not this
  skill's.

## Done when

`review.md` carries its frontmatter and the verdict with findings by severity, the decisive
verification was re-run BY YOU, and the chat summary gives the verdict in two sentences.
Approve only what you would defend in someone else's post-mortem.
