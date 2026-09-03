---
name: dev-implement
description: 'The IMPLEMENTER — stage 2 of the base flow. Takes the TASK NAME, works from the owner-approved memory/spec/<TASK>/analysis.md, makes the smallest sufficient change verifying as it goes, and writes implementation.md for the owner to approve. Invoke: dev-implement <TASK>.'
argument-hint: '<TASK>'
# mcp-docs:on
allowed-tools: [Read, Glob, Grep, Edit, Write, Bash, Agent, mcp__context7__resolve-library-id, mcp__context7__query-docs]
# mcp-docs:off
allowed-tools: [Read, Glob, Grep, Edit, Write, Bash, Agent]
# mcp-docs:end
metadata:
  taut:
    agents: [dev-implementer]
    mcp: [docs]
---

# dev-implement — the implementer (stage 2)

Turn the analysis into a working change.

| | |
|---|---|
| **Invoke** | `dev-implement <TASK>` |
| **Input** | `memory/spec/<TASK>/analysis.md` with `status: approved` |
| **Output** | `memory/spec/<TASK>/implementation.md`, `status: draft` + the working-tree change |
| **Gate** | the owner reads it and approves — see *The owner gate* below |
| **Next** | `dev-review <TASK>` |

## 0. Entry check (do this before touching code)

- No `<TASK>` given → ask; never guess which task is meant.
- `memory/spec/<TASK>/analysis.md` missing or empty → **stop** and run `dev-analyze <TASK>`
  first. Implementing from an unwritten analysis is how scope creeps and root causes get
  guessed.
- `status: draft` in that file → **stop**: the analysis has not passed its gate. Say so and
  ask the owner to approve it (or to tell you explicitly to proceed without it — their call,
  recorded in your summary).
- Read the whole analysis before the first edit. It is the contract for this stage.

## Process (universal)

1. **Work from the analysis**, not from memory of it. Deviating from the sketch is
   fine — record WHY in `memory/spec/<TASK>/implementation.md` as you go. Start that file
   with:

   ```markdown
   ---
   task: <TASK>
   stage: implementation
   status: draft
   ---
   ```
2. **Smallest sufficient change.** Match the surrounding code's conventions (the repo's
   descriptor under `.taut/repos/<repo>/` lists the load-bearing ones); no drive-by
   refactors — surface smells in the summary instead of fixing them inline.
3. **Verify as you go**: after every meaningful step run the TIGHTEST relevant check
   (one test, one build target), not the whole suite; run the wider suite before
   declaring done. A change you have not run is a hypothesis, not a change. Record
   command + outcome for everything you ran.
4. **Delegate parallelizable, well-scoped edits** to the `dev-implementer` subagent
   (one repo, explicit instructions, verification command included); verify its work
   yourself — delegation transfers labor, not responsibility.
5. **Respect the workspace laws** (`.taut/LAWS.md`) — git policy, secrets, scope. The
   default work product is working-tree changes; branch/commit only where the law
   grants it.

## The verify loop in this stack

<!-- stack-node:on -->
**node:** detect the package manager from the lockfile (`package-lock.json` → npm,
`pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn) and USE it — never mix. Targeted test
first: `<pm> test -- <pattern>` / `vitest run <file>` / `jest <file>`; monorepos: run
via the runner (`nx test <project>`, `turbo run test --filter=<pkg>`) so caches and
deps resolve. Then lint + typecheck (`tsc --noEmit`) — type errors are failures even
when the runtime "works". Do not hand-edit lockfiles; a dirty lockfile you did not
intend is a red flag to report.
<!-- stack-node:end -->
<!-- stack-jvm:on -->
**jvm:** compile early — `./gradlew compileJava` / `mvn -q compile` catches most
mistakes fastest. Targeted test: `./gradlew :<module>:test --tests '<Class>'` /
`mvn -pl <module> -Dtest=<Class> test`. Prefer the wrapper (`./gradlew`, `./mvnw`) over
a global tool; respect the version catalogs / dependencyManagement — pin changes are
their own reviewed change, never a side effect. Long builds: scope to the module, not
the world.
<!-- stack-jvm:end -->
<!-- stack-android:on -->
**android:** the fast loop is `./gradlew :app:compileDebugKotlin` (or `compileDebugJavaWithJavac`),
then `:app:testDebugUnitTest` for the JVM-side tests and `:app:lintDebug`. **Instrumented
tests (`connectedDebugAndroidTest`) need a booted emulator or a plugged-in device** —
check `adb devices` before claiming they pass, and say plainly when you could not run
them. Never call `mvn` here. Library versions live in `gradle/libs.versions.toml`;
bumping one is its own reviewed change, never a side effect. Respect `minSdk`: an API
above it needs a version gate, not a shrug. Compose changes deserve a preview or a
screenshot before "done" — recomposition bugs do not show up in unit tests.
<!-- stack-android:end -->
<!-- stack-php:on -->
**php:** run what `composer.json` `scripts` declare — those are the project's own
checks. Targeted test: `vendor/bin/phpunit --filter <TestName>` (or `pest`). Static
analysis (`phpstan`/`psalm`) at the project's configured level is part of done, not
optional. Never edit `vendor/`; `composer.lock` changes only when a dependency change
is the task.
<!-- stack-php:end -->
<!-- stack-python:on -->
**python:** work inside the project's own environment, never the system interpreter:
with a `pyproject.toml` + `uv.lock` that is `uv sync` once and `uv run <cmd>` for every
command below; otherwise a venv (`python -m venv .venv` or `uv venv`) with the pinned
requirements installed. The loop, cheapest first: `ruff check .` (lint) → `ruff format
--check .` (only where the repo already formats with ruff) → `mypy <package>` (or the
type checker the repo configures in `[tool.*]`) → `pytest -q` (`-x` stops at the first
failure, `-k <expr>` narrows; `src/` layouts need the package installed or
`PYTHONPATH=src`). No test suite at all (a scripts repo)? At least `python -m compileall
-q .` and `python -m unittest discover` before handing back. Never edit a lock file by
hand — `uv lock` / `poetry lock` regenerate it, as a separate reviewable change.
<!-- stack-python:end -->

<!-- mcp-docs:on -->
Unfamiliar API mid-change: resolve with the docs MCP (`resolve-library-id` →
`query-docs`) before improvising a usage from memory.
<!-- mcp-docs:end -->

## The owner gate

**STOP here** — do not launch `dev-review` yourself. Report in chat: what changed (file by
file), what you ran and what it said, what you deliberately did NOT do, and anything the
analysis asked for that you could not deliver. Name the file.

On the owner's explicit approval, set `status: approved` in `implementation.md`. Changes
requested → make them, keep `status: draft`, ask again. The status is what a later session
(or the reviewer) reads to know whether this stage really finished.

## Done when

The wider check suite for the touched area passes, `implementation.md` carries its
frontmatter, what changed and the verification evidence (commands + outcomes), the chat
summary states both in three sentences, and the owner has been asked for the gate.
"Done, but I didn't run it" is not a state this skill recognizes.
