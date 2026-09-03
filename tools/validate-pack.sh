#!/usr/bin/env bash
# Validate this data pack by COMPILING it — the only check that proves a change is safe.
#
# A broken commit here breaks every teammate's toolchain on their next `taut update`,
# so run this before you push, and let CI run it on every merge request. It compiles a
# throwaway workspace from each project in the pack against STUB member repos, so it
# needs no access to the real repositories and no secrets.
#
# What compiling proves: frontmatter parses, capability markers are balanced, every repo
# binding exists in the deployment's repo map, flow sequences name installed skills,
# runbook and descriptor references resolve, the MCP catalog is well-formed, the model
# ladder's sessionTier names a real rung — plus a full artifact hash verification.
#
# Usage:
#   tools/validate-pack.sh                      # fetches the PINNED engine commit
#   TAUT_ENGINE=~/taut tools/validate-pack.sh   # uses a local engine checkout instead
#   SAUT=~/saut tools/validate-pack.sh          # adds the SAUT lint step (advisory; SAUT_STRICT=1 enforces)
#
# Requires Node >= 24 and git.
set -euo pipefail

PACK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# The engine is EXECUTED by this script, so it is pinned to an exact commit rather than a
# branch: a moving `master` would mean unreviewed third-party code running in CI, and a
# green pipeline could turn red without a single change in this pack. Raising the pin is a
# deliberate act — bump ENGINE_COMMIT, run this locally against the new engine, and open a
# merge request for it.
#   Engine: https://github.com/yurgeno/taut · v0.7.0 harness capability registry + `taut render`
#           (https://github.com/yurgeno/taut/releases/tag/v0.7.0), pinned 2026-09-03
ENGINE_COMMIT="${TAUT_ENGINE_COMMIT:-74f09962b210c8b0020ba6913c63b0074fb861ea}"
ENGINE_URL="${TAUT_ENGINE_URL:-https://github.com/yurgeno/taut.git}"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
fail() { printf '\033[31mFAILED: %s\033[0m\n' "$1" >&2; exit 1; }

node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 24 ? 0 : 1)' \
  || fail "Node >= 24 required (found $(node -v)) — the engine runs TypeScript natively"

step "Engine"
if [ -n "${TAUT_ENGINE:-}" ]; then
  ENGINE="$(cd "${TAUT_ENGINE/#\~/$HOME}" && pwd)"
  echo "using local checkout: $ENGINE ($(git -C "$ENGINE" rev-parse --short HEAD 2>/dev/null || echo 'not a git repo'))"
else
  ENGINE="$WORK/engine"
  git init --quiet "$ENGINE"
  git -C "$ENGINE" remote add origin "$ENGINE_URL"
  git -C "$ENGINE" fetch --quiet --depth 1 origin "$ENGINE_COMMIT" \
    || fail "cannot fetch engine commit $ENGINE_COMMIT from $ENGINE_URL (offline runner? mirror it and set TAUT_ENGINE_URL)"
  git -C "$ENGINE" checkout --quiet FETCH_HEAD
  # A fetch by SHA cannot return a different commit, but verify anyway: this is the line
  # that makes "we ran exactly this engine" a fact rather than an assumption.
  got="$(git -C "$ENGINE" rev-parse HEAD)"
  [ "$got" = "$ENGINE_COMMIT" ] || fail "engine commit mismatch: expected $ENGINE_COMMIT, got $got"
  echo "engine pinned at ${ENGINE_COMMIT:0:12} from $ENGINE_URL"
fi

# Every project folder (one deployment.json each) is compiled on its own. NUL-delimited so
# a pack checked out under a path with spaces still works.
projects=()
while IFS= read -r -d '' dep; do
  projects+=("$(basename "$(dirname "$dep")")")
done < <(find "$PACK_ROOT" -mindepth 2 -maxdepth 2 -name deployment.json -not -path '*/.git/*' -print0)
[ ${#projects[@]} -gt 0 ] || fail "no project folders found (expected <project>/deployment.json at the pack root)"
echo "projects: ${projects[*]}"

for project in "${projects[@]}"; do
  step "Compiling project: $project"
  land="$WORK/$project"
  mkdir -p "$land"

  # Stub every repo the deployment KNOWS, so the repo-map lint is exercised in full and
  # no artifact is skipped for an unconnected repo. Stubs are empty git repos: the
  # compiler only ever reads their path and git metadata, never their contents.
  # `|| [ -n "$r" ]` is load-bearing: read returns false on a final line with no trailing
  # newline, which would silently drop the last repository from the stub set — and a
  # missing MANDATORY repo fails the compile in a way that looks like a pack defect.
  repo_count=0
  while IFS= read -r r || [ -n "$r" ]; do
    [ -n "$r" ] || continue
    git init -q "$land/$r"
    repo_count=$((repo_count + 1))
  done < <(node -e '
    const map = require(process.argv[1]).repos?.known ?? {};
    process.stdout.write(Object.keys(map).join("\n") + "\n");
  ' "$PACK_ROOT/$project/deployment.json")
  # A GENERIC deployment (empty repo map — this pack's starter) curates nothing: the
  # scan connects whatever exists. Give it one stub so the compile has a landscape.
  if [ "$repo_count" -eq 0 ]; then
    git init -q "$land/stub-repo"
    repo_count=1
    echo "stub repos: 1 (generic deployment — synthetic stub-repo)"
  else
    echo "stub repos: $repo_count"
  fi

  # A KAUT stub keeps KAUT-dependent skills in the compile — without it they are
  # silently skipped and never validated.
  mkdir -p "$land/kaut-stub" && printf '// stub\n' > "$land/kaut-stub/kaut.mjs"

  # Built by node, not by string interpolation: paths and project names reach the file as
  # correctly escaped JSON whatever characters they contain.
  node -e '
    const [project, land] = process.argv.slice(1);
    process.stdout.write(JSON.stringify({
      deployment: project,
      workspace: `${land}/ws`,
      repos: "scan",
      harnesses: ["claude-code", "codex"],
      kaut: `${land}/kaut-stub`,
      skills: "all",
      mcp: "all",
    }, null, 2));
  ' "$project" "$land" > "$land/answers.json"

  # TAUT_DATA is cleared so --data is unambiguous even on a developer machine that has
  # a pack bound elsewhere.
  ( cd "$land" && env -u TAUT_DATA node "$ENGINE/taut.mjs" setup \
      --answers "$land/answers.json" --yes --data "$PACK_ROOT" ) \
    || fail "$project: compile failed (see the error above)"

  node "$ENGINE/taut.mjs" verify --workspace "$land/ws" \
    || fail "$project: artifact verification failed"
done

# Optional: the SAUT privilege/correctness lint over the pack sources (github.com/yurgeno/saut).
# Runs only when SAUT points at a checkout; its findings are REPORTED, not enforced, unless
# SAUT_STRICT=1 — the pack's own compile above stays the gate that decides a merge.
if [ -n "${SAUT:-}" ]; then
  step "SAUT lint (privileges, allowlists, cost)"
  SAUT_DIR="$(cd "${SAUT/#\~/$HOME}" && pwd)"
  if [ "${SAUT_STRICT:-0}" = "1" ]; then
    node "$SAUT_DIR/saut.mjs" lint "$PACK_ROOT" --taut "$ENGINE" || fail "SAUT lint reported high findings (SAUT_STRICT=1)"
  else
    node "$SAUT_DIR/saut.mjs" lint "$PACK_ROOT" --taut "$ENGINE" || echo "(SAUT findings above are advisory — set SAUT_STRICT=1 to enforce)"
  fi
fi

step "Result"
echo "OK — every project in this pack compiles and verifies."
