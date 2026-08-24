---
summary:
  - "Verify before claiming: a change that was not run is a hypothesis, not a result."
  - "Member-repo git defaults to READ-ONLY for agents — adjust L2 to YOUR project's policy."
  - "Smallest sufficient change; out-of-scope findings are reported, not fixed inline."
  - "Secret VALUES never enter the pack, the chat, or any artifact — env names only."
---

# Deployment laws — baseline (edit me)

The workspace's non-negotiables. This baseline is deliberately small and generic —
REPLACE the placeholders with your project's real policy and delete this sentence.
Laws are read by every session; keep each one short enough to be remembered.

## L1 — Verify before claiming
"Done" is a claim backed by evidence: the relevant check ran, its outcome is recorded
in the task's memory folder. Static reading yields hypotheses; only running confirms.
Confidence without verification does more damage than an admitted gap.

## L2 — Member-repo git policy (PLACEHOLDER — set yours)
Default: agents treat member repos as READ-ONLY for git state — work product is
working-tree edits; branches/commits/pushes belong to humans. If your project grants
agents more (e.g. commits to feature branches), write the exact grant here; an unwritten
grant does not exist.

## L3 — Scope discipline
Smallest sufficient change for the task at hand. Smells, dead code, and adjacent bugs
discovered on the way are SURFACED in the summary — not silently fixed, not silently
ignored.

## L4 — Memory discipline
Each task keeps its artifacts in `memory/spec/<TASK>/` (analysis, implementation notes,
review). Past task folders are consulted READ-ONLY as prior art. Memory is instance
data: the framework never rewrites it, and neither does a later task.

## L5 — Secrets
Values live in each developer's `.taut/local.env` and nowhere else. Artifacts, packs,
chats, and memory carry env variable NAMES at most. Citing a value "just this once" is
the leak.
