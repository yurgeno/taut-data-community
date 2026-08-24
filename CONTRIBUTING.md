# Contributing

Improvements to the base skills, new stack branches, new generic skills, and manual
fixes are all welcome. Ground rules:

- **Generic only.** No project names, no company specifics, no secrets — this pack must
  serve ANY project. Instance material belongs in your own (private) pack.
- **Validate before you push:** `TAUT_ENGINE=<your engine checkout> tools/validate-pack.sh`
  (or let it fetch the pinned engine). CI runs the same script on every push; a red
  pipeline blocks the merge.
- **Stack branches are open vocabulary.** Adding a toolchain = adding
  `<!-- stack-<name>:on --> … <!-- stack-<name>:end -->` branches where the mechanics
  differ, plus (if the engine cannot detect it) documenting the `stack` declaration in
  ADAPTING.md. Keep branches honest: only write what you have actually verified on that
  toolchain.
- **English**, imperative commit messages, one logical change per commit.
- **No secrets, ever:** `tools/scan-secrets.sh` sweeps tracked files for credential
  shapes; env variable NAMES and short placeholders are fine, values are not.
