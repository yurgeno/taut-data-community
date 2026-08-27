# Getting started — from this template to your compiled workspace

~15 minutes. You need Node ≥ 24, git, and your project's repositories under one folder
(the "landscape root"). They may sit directly in it, or be grouped in a project folder —
the scan looks two levels deep, so `landscape/{web,api}` and `landscape/travel/{web,api}`
both work.

On Windows, run everything **inside WSL** — see [Windows + WSL](#windows--wsl) below.

## 1. Take the pack

```bash
cd <your-landscape-root>          # the folder holding your repos
git clone https://github.com/yurgeno/taut-data-community taut-data
```

The folder name `taut-data` matters: the engine resolves a workspace's pack by that
sibling name (explicit `--data <dir>` always works too). Using GitHub's **Use this
template** button first gives you your own repository to push pack changes to — do
that if the pack will evolve with your project (it will).

## 2. (Optional) make the template yours

The pack compiles AS-IS: `starter/` ships an empty repo map, which means "no curation"
— setup connects every repository the scan finds and scaffolds a descriptor for each.
For a first run, skip straight to step 3.

When you adopt it for real:

```bash
cd taut-data
mv starter myproject                       # your project's name
$EDITOR myproject/deployment.json
```

In `deployment.json`: set `"name": "myproject"` (must equal the folder name), and —
only if you want curation — describe repos in `repos.known` (folder basename → role,
plus a `stack` declaration where the file-probe detection isn't enough; a non-empty
map filters the scan to what it names). Then open `myproject/docs/LAWS.md` and replace
the placeholder policies with your project's real ones (especially L2, the git policy).

## 3. Compile a workspace

```bash
cd <your-landscape-root>
git clone https://github.com/yurgeno/taut
node taut/taut.mjs setup
```

The questionnaire asks for: the data pack (defaults to the sibling), the deployment
(`starter` — or your renamed project), the workspace folder, your repos (auto-scanned from the landscape root),
the harness(es), KAUT (pick *disable* if you don't know what it is), the workspace
mode, the telemetry level (stored ONLY on your machine, never sent anywhere), and the
skills/MCP checklists — pick **all** skills to get the drop-in contract
(new pack skills auto-install on `update`). If you enabled KAUT, also tick the `kaut`
MCP server in the checklist — that is what puts the knowledge tools into every session
(the engine folder you gave is compiled in as `KAUT_ENGINE`).

## 4. Teach the workspace your repositories

Open the workspace with your harness and run one skill:

```
/workspace-init
```

setup already created a descriptor skeleton for each connected repository under
`repos/<name>/descriptor.md` in the workspace. This skill fills them IN PLACE: what the
repo is, its entry points, build/test commands it VERIFIED by running them, layout,
conventions, gotchas — mining any `CLAUDE.md`/`AGENTS.md` the repositories already carry
as source material — plus `repos/LANDSCAPE.md` for multi-repo projects. Nothing to commit
or install: the files are live, and your review of them is the gate.

Then `/workspace-check` — the readiness skill: engine sweep plus the live proofs (every
repo covered by a descriptor that still matches it, every MCP server answering, the whole
toolchain readable), ending in READY / NOT READY with a fix per failure.

Skip this and every session starts by rediscovering how your project builds.

## 5. What you got

Open the workspace folder with your harness. The three base skills are installed
**already specialized for your repos' toolchains** — the compiler scanned the connected
repos and kept exactly the matching stack branches. Also there: `.taut/LAWS.md` (your
laws), the flow doc, an MCP launcher (fill `.taut/local.env` if you enabled servers),
and an integrity gate wired into the harness hooks.

```bash
cd <workspace> && node ui       # the panel: status, checklists, update/repair buttons
node ui status                  # am I current?  · node ui check — can work run here?
```

## 6. Daily life

- Run the flow: `dev-analyze` → `dev-implement` → `dev-review` (see `.taut/docs/FLOW-dev.md`).
- Pack changed? `node ui update` re-pins and recompiles; your selections survive.
- Repos without descriptors: `node ui repo-scaffold` writes the missing skeletons into
  the workspace; `/workspace-init` fills them.
- Something feels off: `/workspace-check` for the full picture, or `node ui check` then
  `node ui repair` for the deterministic half.

## My repository already has a CLAUDE.md

Keep it. TAUT never touches member repositories: its knowledge lives in the workspace
(`repos/<name>/descriptor.md`, or `.taut/repos/` when your pack ships one), and sessions
launched from the workspace use ONLY those — your existing file is neither followed nor
modified. `workspace-init` mines it as source material: what still holds is carried over
(verified), what has gone stale is flagged, and every conflict is named explicitly rather
than silently overridden.

Some tooling even regenerates such files on its own (Next.js writes `AGENTS.md`/`CLAUDE.md`
whenever it detects an agent harness). That is fine: one truth lives in the workspace, and
it is the senior one.

## Windows + WSL

TAUT runs on Linux and macOS; on Windows that means **inside WSL**, not PowerShell.

- Keep the repositories and the workspace in the **WSL filesystem** (`~/projects/...`),
  not under `/mnt/c` — git and file watching there are an order of magnitude slower.
- **Set `git config core.autocrlf input`** (or `false`) in WSL. This matters more than it
  looks: the integrity gate hashes every installed artifact, and CRLF line endings change
  those hashes — you would get "drifted" verdicts on files nobody touched.
- Run `node -v` **inside WSL** — the Windows-side Node does not count.
- Start your harness from a WSL shell, so its paths and the workspace's paths are the same
  world.
- Docker, if your project needs it: Docker Desktop with WSL integration enabled.

Next: [ADAPTING.md](ADAPTING.md) — growing the pack with your own skills, stacks, and
runbooks.
