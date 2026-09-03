# taut-data-community

[![validate](https://github.com/yurgeno/taut-data-community/actions/workflows/validate.yml/badge.svg)](https://github.com/yurgeno/taut-data-community/actions/workflows/validate.yml)
[![release](https://img.shields.io/github/v/release/yurgeno/taut-data-community)](https://github.com/yurgeno/taut-data-community/releases)
[![license](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)
[![template](https://img.shields.io/badge/template-use%20this%20pack-2ea043)](https://github.com/yurgeno/taut-data-community/generate)
[![engine](https://img.shields.io/badge/built%20for-TAUT-informational)](https://github.com/yurgeno/taut)
![stacks](https://img.shields.io/badge/stacks-node%20%7C%20jvm%20%7C%20php%20%7C%20python%20%7C%20android-lightgrey)
![secrets](https://img.shields.io/badge/secrets%20in%20pack-0-success)

The **community starter data pack** for [TAUT](https://github.com/yurgeno/taut)
(Toolchain Actualization Under Trust). TAUT compiles a harness-neutral data pack —
skills, agents, laws, MCP pins, per-repo knowledge — into a locked, integrity-gated
**workspace** for your agent harness. This pack is the fastest honest way to put TAUT
on **any project**: fork it, rename one folder, compile.

## What you get

- **Three base skills** — `dev-analyze` (the analyst), `dev-implement` (the
  implementer), `dev-review` (the reviewer) — a complete minimal dev flow. Their bodies
  carry per-toolchain branches (`node`, `jvm`, `php`, `python`, `android`) in capability markers; the
  compiler **scans your connected repos** (or reads your declaration) and keeps exactly
  the branches your project needs. The installed skills are already specialized —
  nothing to configure.
- **Three matching subagents** plus a repo scout — for isolated recon, focused
  implementation, and independent review.
- **`workspace-init`** — run once after compiling: it studies every connected
  repository (read-only) and fills the workspace-owned descriptor
  (`repos/<name>/descriptor.md`) with verified working knowledge — build/test commands
  it actually ran, layout, conventions, gotchas. Sessions read those descriptors;
  member repositories are never modified.
- **`workspace-check`** — the readiness probe: descriptor coverage and drift, MCP
  servers answering, toolchain readable — READY / NOT READY with a fix per failure.
- **A template deployment** (`starter/`) — annotated `deployment.json` (repo map
  deliberately empty: setup scans your landscape and connects what it finds), baseline
  laws, and the documented flow. Works as-is; rename and curate when you adopt it.
- **A pinned MCP catalog** — context7 (library docs) and playwright (browser
  verification) ready to enable.
- **Validation you can trust** — `tools/validate-pack.sh` compiles every project in
  the pack against a pinned engine commit (the same check CI runs on every push).

## Quickstart

```bash
# 1. Next to your project's repositories, clone this pack AS `taut-data`
#    (the engine finds a workspace's pack by that sibling name):
git clone https://github.com/yurgeno/taut-data-community taut-data

# 2. Get the engine and compile a workspace (interactive questionnaire —
#    setup scans your repos, connects them, scaffolds a descriptor per repo):
git clone https://github.com/yurgeno/taut
node taut/taut.mjs setup

# 3. Open the workspace with your harness and run /workspace-init —
#    it fills each repo descriptor with verified working knowledge.
```

To make the pack yours later: rename `starter/` to your project's name, write your
laws, curate the repo map — [manual/ADAPTING.md](manual/ADAPTING.md).

Step-by-step guide: [manual/GETTING-STARTED.md](manual/GETTING-STARTED.md) ·
adapting and extending: [manual/ADAPTING.md](manual/ADAPTING.md) ·
authoring reference: the engine's `docs/PACK.md` and `docs/TUTORIAL.md`.

## Toolchains the branches cover

| Stack | Detected by the engine | What the branches know |
|---|---|---|
| `node` | `package.json` | npm / nx / turbo monorepos, `tsconfig` paths, Next / Vite entry points, type-check + test + lint loop |
| `jvm` | `pom.xml`, `build.gradle(.kts)`, `settings.gradle(.kts)` | Maven / Gradle modules, Spring entry points and profiles, wrapper-driven build + test |
| `android` | declared (`"stack": ["jvm", "android"]`) | Gradle modules, manifest / Compose entry, Hilt wiring, `minSdk`, emulator / `adb`, R8 rules |
| `php` | `composer.json` | PSR-4 autoload map, Nette / Laravel / Symfony entry points, composer scripts |
| `python` | `pyproject.toml` (PEP 621 / Poetry / PDM / uv / Hatch), `requirements*.txt` + `requirements/*.txt`, `setup.py` / `setup.cfg`, `Pipfile`, `environment.yml`, `uv.lock` / `poetry.lock` / `pdm.lock` — or plain `*.py` scripts (root, `scripts/`, `bin/`) | `uv sync` / `uv run` or venv workflows, `src/` and flat layouts, Django (`manage.py`, apps, `urls.py`, migrations), FastAPI / Flask decorators, DRF routers, plain-script repos; verify loop `ruff check` → `ruff format --check` → `mypy` (or the configured checker) → `pytest`, `compileall` + `unittest discover` as the floor; lock files never edited by hand |

Any other toolchain (`go`, `rust`, or a name you declare) compiles without a branch —
the universal process still applies; add a branch when you have verified knowledge to
put in it ([manual/ADAPTING.md](manual/ADAPTING.md)).

## Adding a skill is copying a file

Drop `skills/<name>/SKILL.md` into the pack — the skill declares its own wiring in its
frontmatter, there is no central registry to edit. A workspace set up with the `all`
skills selection installs it on its next `node ui update`, already passed through the
capability and stack gates. That is the whole procedure.

## Principles

- **Universal core, specific compile.** Base skills are toolchain-free process; stack
  knowledge lives in marked branches; your repos decide which branches ship.
- **Nothing here is secret.** MCP entries carry env variable NAMES only; CI runs a
  secret-shape scan (`tools/scan-secrets.sh`). Values live in each developer's
  `.taut/local.env`, never in a pack.
- **A pack is code.** Review changes, run validation before pushing, let CI gate
  merges — a broken pack commit breaks every teammate's next update.

## License

[Apache-2.0](LICENSE). Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).
