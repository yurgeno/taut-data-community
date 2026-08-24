# Adapting the pack — skills, stacks, runbooks, MCP

The engine's `docs/PACK.md` is the authoring REFERENCE; this manual is the short path
for the common moves on THIS template. Validate after every change:
`tools/validate-pack.sh` (add `TAUT_ENGINE=<engine checkout>` to use a local engine).

## Add a skill (the whole procedure)

Copy a `skills/<name>/SKILL.md` file into the pack — shared root `skills/` for
every-project skills, `<project>/skills/` for project-only ones. The skill declares its
own wiring in frontmatter (`metadata.taut`: agents it needs, `requires: [atlas]`,
`repos` bindings, `mcp` roles); there is no registry to edit and `deployment.json` is
not involved. A workspace with the **all** skills selection installs it on its next
`node ui update`, already passed through the capability and stack gates. Don't want one
skill somewhere? `taut apply --disable-skill <name>` — "all minus exclusions".

## Add or refine a STACK branch

Where a skill's mechanics depend on the toolchain, branch it:

```markdown
<!-- stack-node:on -->
…node-specific verify loop…
<!-- stack-node:end -->
```

The vocabulary is OPEN: any `stack-<name>` works; a branch whose stack no connected
repo has simply compiles out. The compiler detects `node` / `jvm` / `php` / `python` /
`go` / `rust` from marker files (package.json, pom.xml/build.gradle*, composer.json,
…); anything else — or a repo the probes misread — gets an explicit declaration in the
deployment: `"repos": { "known": { "api": { "stack": "elixir" } } }` (declaration beats
detection). Keep branches honest: write only what you verified on that toolchain.

This pack ships `node`, `jvm`, `php` and **`android`** branches. Android is a declared
stack, not a detected one: a Gradle project probes as `jvm`, so an Android repo declares
`"stack": ["jvm", "android"]` and gets both branches — the JVM toolchain advice plus the
emulator/`adb`/`minSdk` specifics.

## Per-repo knowledge (descriptors)

Two homes, one index (manifest `repoDocs`):

- **Workspace-owned (the default).** Every compile ensures `repos/<name>/descriptor.md` in
  the WORKSPACE for each connected repo the pack does not cover — a skeleton carrying a
  brief and the detected toolchain. The **`workspace-init`** skill fills it in place
  (verifying commands by running them, mining repo-internal instruction files as source
  material, writing `repos/LANDSCAPE.md`). Instance data: not integrity-locked, never
  overwritten by an update, no commit or install step. Target quality:
  [EXAMPLE-repo-descriptor.md](EXAMPLE-repo-descriptor.md).
- **Pack-shipped (authoring).** A deployment that wants reviewed, distributed, hash-locked
  descriptors puts them in `<project>/repos/<repo>/*.md`; `node ui repo-scaffold --pack`
  writes the skeletons there (the repo must be in the deployment's repo map). Commit the
  pack, `node ui update` installs them under `.taut/repos/`.

A repo is under exactly one regime — pack coverage wins. Member repositories are never
written in either case.

## Runbooks

`<project>/runbooks/<name>.md` — frontmatter (`name`, `description`, optional `repos:`
bindings) + a body an agent can follow verbatim: prerequisites, steps with commands,
verification, teardown. Record only VERIFIED commands. Runbooks index into the manifest
and ship as `.taut/runbooks/`.

## MCP servers

Add an entry to `catalog/mcp.json` (or `<project>/catalog/mcp.json`): role, `serverKey`
(must match the `mcp__<serverKey>__*` tool namespace), package + exact `pin`, `command`
/`args`, env variable NAMES (+ `envHelp` lines — they render into `.taut/local.env`
placeholders). Existing workspaces enable it with `taut apply --enable-mcp <id>`.
Values never enter the pack; verify pins upstream and note the provenance in the
commit message.

## Laws and flow

`<project>/docs/LAWS.md` — your non-negotiables (frontmatter `summary` renders into
the instructions; keep it in sync with the body). `docs/FLOW-*.md` — a flow is nothing
but a documented launch order (`sequence:`) over installed skills; edit or add flows
freely, they ship when their sequence touches an installed skill.

## Keep it compiling

CI runs `tools/scan-secrets.sh` + `tools/validate-pack.sh` on every push. The
validation compiles EVERY project in the pack against stub repos with a PINNED engine
commit — bump `ENGINE_COMMIT` in `tools/validate-pack.sh` deliberately (run locally
against the new engine first), never point it at a moving branch.
