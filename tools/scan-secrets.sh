#!/usr/bin/env bash
# Refuse to ship a credential. SECURITY.md says values never belong in this repository;
# this is the mechanical half of that promise, because a rule nobody checks is a wish.
#
# GitLab's own Secret Detection is an Ultimate feature and this instance is Community
# Edition, so the check is a small pattern sweep over the tracked files. It looks for
# credential SHAPES, not for the word "token" — declaring env variable NAMES and short
# placeholder examples is exactly what the pack is supposed to do.
#
# Usage: tools/scan-secrets.sh          (run from anywhere; scans tracked files only)
# Requires git and grep.
set -euo pipefail

PACK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PACK_ROOT"

# Each entry: <label>|<extended regex>. Kept deliberately narrow — a pattern that cries
# wolf gets disabled by the first person it annoys, and then it protects nothing.
PATTERNS=(
  'private key block|-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'GitLab PAT|glpat-[A-Za-z0-9_-]{20,}'
  'GitHub token|gh[pousr]_[A-Za-z0-9]{36,}'
  'Atlassian API token|ATATT[A-Za-z0-9_=-]{30,}'
  'AWS access key|AKIA[0-9A-Z]{16}'
  'Slack token|xox[abprs]-[A-Za-z0-9-]{10,}'
  'JWT|eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.'
  'npm token|npm_[A-Za-z0-9]{36}'
  'URL with embedded credentials|[a-z][a-z0-9+.-]*://[^/[:space:]:]+:[^/[:space:]@]+@'
  'assigned secret value|(password|passwd|secret|api[_-]?key|access[_-]?token)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'[:space:]]{8,}'
)

found=0
while IFS= read -r -d '' file; do
  # Skip this scanner: it necessarily contains the patterns it hunts for.
  [ "$file" = "tools/scan-secrets.sh" ] && continue
  for entry in "${PATTERNS[@]}"; do
    label="${entry%%|*}"
    regex="${entry#*|}"
    # -e is mandatory, not style: the private-key pattern starts with a dash and grep
    # would otherwise read it as an option and silently never match.
    if hits="$(grep -nIE -e "$regex" -- "$file" 2>/dev/null)"; then
      found=1
      # Report the LOCATION and the finding's kind — never echo the matched value.
      while IFS= read -r hit; do
        printf '\033[31m%s\033[0m  %s:%s\n' "$label" "$file" "${hit%%:*}"
      done <<< "$hits"
    fi
  done
done < <(git ls-files -z)

if [ "$found" -ne 0 ]; then
  cat >&2 <<'EOF'

FAILED: something shaped like a credential is tracked in this repository.

If it is real: rotate it FIRST (assume it is compromised), tell the owners, then remove
the value. See SECURITY.md — history rewriting is a coordinated action, not a quick fix,
because every workspace pins a pack commit.

If it is a false positive: make the example obviously fake (shorten it, or write it as
<your-token-here>), or narrow the pattern in tools/scan-secrets.sh with a comment saying
why.
EOF
  exit 1
fi

echo "OK — no credential-shaped strings in the tracked files."
