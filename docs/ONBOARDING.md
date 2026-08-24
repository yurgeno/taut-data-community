# Onboarding a project — the order of operations

Four steps, once per project. Everything after that is `update` and the dev flow.

```bash
node <engine>/taut.mjs setup   # 1. connect repos, pick harness + skills, compile
                               # 2. open the workspace with your harness
/workspace-init                # 3. fill the repo descriptors + the landscape map
/workspace-check               # 4. prove the session is ready
```

**1. setup** scans the landscape root two levels deep (repositories directly in the root,
and repositories inside a project folder), then compiles the pack into a workspace: skills
specialized for the connected repos' toolchains, the laws, the flow docs, the integrity
gate wired into your harness — and a descriptor SKELETON under `repos/<name>/` for every
connected repository.

**2. open the workspace**, not a repository — the workspace is where the skills, the laws
and the repo knowledge live. Member repositories stay untouched by design: sessions use
ONLY the workspace's descriptors, and instruction files inside a repo are neither followed
nor modified.

**3. `workspace-init`** is the one skill you run before any real work: it fills each
repo's skeleton IN PLACE with commands it VERIFIED by running them, layout, conventions
and gotchas — mining any instruction files the repositories already carry as source
material — and, for multi-repo projects, writes `repos/LANDSCAPE.md`, the map no single
repository holds. The files are live immediately; your review of them is the gate.

**4. `workspace-check`** runs the engine sweep (`check` + `verify`) and adds the proofs
only a live session can make — every repo covered by a descriptor that still matches it,
every MCP server answering a real call, the whole toolchain readable — and ends with
READY / NOT READY plus a fix per failure.

Connecting another repository later? Its skeleton appears on that compile; re-run
`workspace-init` — it fills only what is missing.

Then the work itself: `dev-analyze` → `dev-implement` → `dev-review` (see FLOW-dev).
