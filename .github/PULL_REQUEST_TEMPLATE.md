## What this changes

<!-- The user-visible effect on a compiled workspace, one or two sentences. -->

## Checklist

- [ ] `tools/validate-pack.sh` is green (every project compiles against the pinned engine)
- [ ] `tools/scan-secrets.sh` is clean — env variable NAMES and placeholders only, never values
- [ ] Generic only: no project names, company specifics, or instance values (those belong in your own pack)
- [ ] Stack branches (`<!-- stack-<name>:on --> … :end -->`) only state what was actually verified on that toolchain
- [ ] Manuals (`manual/`, `docs/`) updated in this PR if the behavior they describe changed
