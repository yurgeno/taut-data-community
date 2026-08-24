---
name: workspace-check
description: 'READINESS — prove this session can actually do the work: every connected repo has a descriptor and is reachable, every installed skill/agent/doc is readable, every MCP server answers a real call, memory is writable. Runs the deterministic engine sweep first, then the proofs only a live session can make. Read-only; ends with a READY / NOT READY verdict and a fix per failure. Use after setup or update, before starting real work, or whenever the toolchain feels off.'
# mcp-docs:on
allowed-tools: [Read, Glob, Grep, Bash, mcp__context7__resolve-library-id, mcp__context7__query-docs]
# mcp-docs:off
allowed-tools: [Read, Glob, Grep, Bash]
# mcp-docs:end
metadata:
  taut:
    mcp: [docs]
---

# workspace-check — is this session ready to work?

Run from the workspace root. **Read-only everywhere**: no member-repo edits, no memory
writes, no pack writes, no bring-up. The product is a chat report.

`node ui check` proves the workspace is wired; this skill proves THIS SESSION can use it —
the difference between "the servers launch" and "I can call them", between "a descriptor
file exists" and "it still describes that repo".

## 0. The deterministic half

```bash
node ui check      # integrity, gate self-test, repos reachable, data readable, MCP handshake
node ui verify     # installed artifacts == what the lock says
```

Capture both. Their ✖ / ! lines seed your report — do not re-derive what they already
answered. That this skill runs at all is itself a proof: the gate admitted a managed
skill in this session.

## 1. Inventory — what "everything" means here

Read `manifest.json`: `skills`, `agents`, `repoDocs`, `flowDocs`, `docs`, `repos`, `mcp`,
`mode`, `atlas.enabled`. Every entry must be covered below — nothing sampled, nothing
skipped in silence. Anything you cannot cover is UNKNOWN with the reason, never "passing".

## 2. Descriptor coverage (the question this skill exists for)

For every repo in `manifest.repos` (the index maps each repo to its home — `.taut/repos/`
for pack-installed files, `repos/<name>/descriptor.md` for workspace-owned ones):

- **Covered?** It must appear in `manifest.repoDocs` with at least one existing, readable
  file. Missing = ✖ **NOT READY for that repo** — the fix is one line: `node ui
  repo-scaffold`, then the **`workspace-init`** skill to fill what it created.
- **Distilled?** Read the descriptor. Still carrying `STATUS: SKELETON` = ! — the
  workspace works, but that repo's knowledge is a stub and agents are told to ignore it.
  Fix: run **`workspace-init`** (it fills skeletons in place).
- **Still true?** Each descriptor carries a `derived: <repo>@<sha>` anchor. Compare it
  with the repo's current HEAD (`git -C <path> log -1 --format=%h`). Far behind = !
  *stale-risk*, and spot-check ONE load-bearing fact — usually the build tool or the test
  command it names. If the repo contradicts the descriptor, report DRIFT: the code is the
  truth (a descriptor is a distilled snapshot, not an authority over the code).
- **Landscape:** more than one repo connected → `repos/LANDSCAPE.md` should exist; its
  absence is ! (cross-repo knowledge lives nowhere else).

Repo paths come from `.taut/local.json → repoPaths`.

## 3. Repos are reachable and sane

For each repo: `git -C <path> status --short` and `git -C <path> branch --show-current`.
Record reachable / branch / dirty. A dirty tree is information, not a failure — but say
so, because half the confusing failures in a session start there. No fetch, no checkout,
no writes.

## 4. The toolchain is readable

- Every installed skill's `SKILL.md` and every agent file — present and readable.
  Integrity already hash-proved them; this proves THIS session can read its own tools.
- `.taut/LAWS.md`, every flow doc, and the other installed docs (`ONBOARDING.md`,
  `LANDSCAPE.md` when present) — readable, and each flow's `sequence` names skills that
  are actually installed.
- Memory: `memory/` resolves and is writable (the engine sweep already checked this —
  just carry its verdict).

## 5. MCP servers answer for real

The engine handshake proved the servers LAUNCH. Now prove this session can CALL them.
For each server in `manifest.mcp`, make ONE cheap **read-only** call:

<!-- mcp-docs:on -->
- **docs (context7):** `resolve-library-id` for a library the project actually uses (take
  one from a repo descriptor's stack section). A resolved id = the call path works.
<!-- mcp-docs:end -->
- Any other server: its cheapest read tool. Reads only — never a write, a comment, a
  transition or anything that changes state elsewhere. Never echo credentials or tokens.

Tools absent from the session, or the call fails → ✖ for that server, with the fix: fill
`.taut/local.env` (nothing to export — servers launch through `.taut/mcp-launch.mjs`,
which reads the file itself), approve the workspace's MCP servers in your harness, then
reconnect MCP or restart the session so the server relaunches with the filled values.

No MCP servers configured? Report "mcp: none configured" — that is a valid state, not a
failure.

<!-- atlas:on -->
## 6. Atlas

Atlas is enabled here. From a member-repo root (store resolution is cwd-based) run only
READ verbs — `paths`, `doctor`, `lookup`, `stale` — never anything that writes to a store.
Report: does the binding resolve, are the stores healthy, does one live `lookup` render a
doc with its freshness verdict. Per-doc `stale` verdicts are INFORMATION (the machinery
working), `broken` / `tampered` are ✖ — report, never repair.
<!-- atlas:off -->
## 6. Atlas

Disabled in this workspace — confirm no installed skill requires it and report
"atlas: not applicable".
<!-- atlas:end -->

## Report

A table per area (engine sweep · descriptors · repos · toolchain · MCP · atlas), each row
✔ / ! / ✖ with one line of evidence — the command run or the file read. Then the verdict:

- **READY** — practical work can start.
- **READY WITH WARNINGS** — it works; the `!` items will cost time later (skeleton
  descriptors, stale anchors, dirty trees).
- **NOT READY** — with the shortest fix per ✖, in the order they should be applied.

Never report a check as passing because it "should" pass. An unrun check is UNKNOWN.
