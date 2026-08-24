---
name: dev-analyze
description: 'The ANALYST — stage 1 of the base flow. Takes a TASK NAME and, on a first run, a short description of what is wanted: scaffolds memory/spec/<TASK>/, understands the task against the actual code, and writes analysis.md for the owner to approve. Invoke: dev-analyze <TASK> [description…].'
argument-hint: '<TASK> [description…]'
# mcp-docs:on
allowed-tools: [Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, mcp__context7__resolve-library-id, mcp__context7__query-docs]
# mcp-docs:off
allowed-tools: [Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion]
# mcp-docs:end
metadata:
  taut:
    agents: [dev-analyst]
    mcp: [docs]
---

# dev-analyze — the analyst (stage 1)

Understand BEFORE changing. Understanding that was never written down does not survive the
next session, so the deliverable is a file, not a conversation.

| | |
|---|---|
| **Invoke** | `dev-analyze <TASK> [description…]` |
| **Input** | the task name + (first run) a description of what is wanted; the code |
| **Output** | `memory/spec/<TASK>/analysis.md`, `status: draft` |
| **Gate** | the owner reads it and approves — see *The owner gate* below |
| **Next** | `dev-implement <TASK>` |

## 0. Task name and workspace

`<TASK>` is the name this piece of work is known by — a tracker id (`ABC-142`), or a
short kebab slug when there is no tracker (`events-filter-by-city`). It names the folder
every stage of this flow reads and writes, so it must be stable for the whole task.

- No `<TASK>` given → ask for one; never invent it, and never guess it from the
  description.
- Accept `[A-Za-z0-9._-]+` only: no slashes, no spaces, no `..` (the name becomes a path).
- Scaffold, idempotently — an existing non-empty file is NEVER clobbered:

```bash
T="<TASK>"; D="memory/spec/$T"
mkdir -p "$D"
for f in analysis implementation review; do [ -e "$D/$f.md" ] || : > "$D/$f.md"; done
```

- `analysis.md` already non-empty? Read it first, then say plainly whether you are
  RESUMING it (the task moved on, extend the file) or REDOING it (the earlier analysis is
  wrong) — and get the owner's word before overwriting approved work.
- The description argument matters on the first run only; afterwards the file is the
  truth. Record it verbatim under "Task" so nobody has to reconstruct what was asked.

## Process (universal)

1. **Restate the task** in two sentences: what should be different when this is done,
   and how that will be observed. Unclear intent → ask now, not after the diff.
2. **Locate the affected area.** Start from the workspace's repo knowledge: the
   manifest's `repos[]` roles, then `.taut/repos/<repo>/` descriptors for the
   candidates. Only then read code.
<!-- atlas:on -->
3. **Consult Atlas first** (`atlas lookup` against the relevant store) per the trust
   hierarchy: distilled docs carry freshness verdicts — a healthy doc routes you,
   a stale one warns you. Confirm anything load-bearing in code.
<!-- atlas:end -->
4. **Ground every claim.** A conclusion drawn from reading code is a HYPOTHESIS until
   confirmed against runtime behavior or a test; label each finding `confirmed` (how)
   or `hypothesis` (what would confirm it). Reading under-determines live behavior.
5. **Delegate wide recon** — scanning many files or repos — to the `dev-analyst`
   subagent and keep only its conclusions in your context.
6. **Write the analysis** to `memory/spec/<TASK>/analysis.md`, starting with the block
   below, then: the task as given, affected repos/files, root cause or design point (with
   its confidence label), the sketch of the change, what could break, and the verification
   the implementer must run. Small task → short analysis; never skip the file.

   ```markdown
   ---
   task: <TASK>
   stage: analysis
   status: draft
   ---
   ```

## Locating things in this stack

<!-- stack-node:on -->
**node (JavaScript / TypeScript):** the repo's `package.json` is the map — `scripts`
tell you how it builds/tests/lints, `workspaces` / `nx.json` / `turbo.json` reveal a
monorepo (route by project, not by folder guessing). Entry points: `main`/`exports` in
package.json, `src/index.*`, framework conventions (`pages/`/`app/` for Next,
`src/main.*` for Vite/Vue). `tsconfig.json` paths explain "impossible" imports. Trace
imports with Grep on the specifier, not the filename — barrel files (`index.ts`) hide
the real source.
<!-- stack-node:end -->
<!-- stack-jvm:on -->
**jvm (Java / Kotlin):** modules come from `pom.xml` (`<modules>`) or
`settings.gradle(.kts)` — read those before assuming layout. Code lives under
`src/main/{java,kotlin}`, tests under `src/test/...`; Spring apps route from the
`@SpringBootApplication` class and `application.yml`/`.properties` (profiles!).
Find usages by fully-qualified names; annotations (`@Autowired`, `@Bean`,
dependency-injection wiring) mean the call graph is not the text graph — check the
configuration classes too.
<!-- stack-jvm:end -->
<!-- stack-android:on -->
**android (Kotlin/Java + Gradle):** the module map is `settings.gradle(.kts)` — a
single-module app puts everything under `app/`. Start from `AndroidManifest.xml`
(entry activities, permissions, exported components), then the Compose entry
(`MainActivity` → the root composable) or the legacy Activity/Fragment tree.
Dependency injection is annotation-wired (Hilt modules) — the call graph is not the text
graph. Versions and libraries come from `build.gradle(.kts)` plus
`gradle/libs.versions.toml`; `minSdk` decides which APIs are even legal. Navigation
routes, resources (`res/`) and DataStore/Room schemas are separate maps worth reading
before changing UI or storage.
<!-- stack-android:end -->
<!-- stack-php:on -->
**php:** `composer.json` is the map — `autoload.psr-4` gives the namespace→directory
translation (trace classes through it, not by guessing paths), `scripts` list the
runnable checks. Framework entry points differ (Nette: `app/Bootstrap.php` + DI configs
in `config/*.neon`; Laravel: `routes/` + providers; Symfony: `config/` + attributes) —
identify the framework first, from composer dependencies.
<!-- stack-php:end -->

<!-- mcp-docs:on -->
Library/framework API questions: resolve with the docs MCP first
(`resolve-library-id` → `query-docs`); web search is the fallback.
<!-- mcp-docs:end -->

## The owner gate

**STOP here.** Written analysis → owner review → act (this is the workspace's collaboration
law, not this skill's preference). Report a one-paragraph summary in chat, name the file,
and ask for approval. Do not launch `dev-implement` yourself.

The approval must survive the session, so it lives in the file: when the owner approves,
set `status: approved` in the frontmatter — on their explicit word, never on your own
judgment that the analysis looks fine. Corrections requested → fix the file, stay `draft`,
ask again.

## Done when

`analysis.md` exists with its frontmatter block, every claim carries its confidence label,
the implementer could start without asking you anything, and the owner has been asked for
the gate.
