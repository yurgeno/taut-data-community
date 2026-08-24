# Security

**No credential values belong in this repository** — the pack ships env variable NAMES
and placeholders only; every developer's real values live in their workspace's
`.taut/local.env` (never committed, never compiled into artifacts).
`tools/scan-secrets.sh` is the mechanical half of that promise and runs in CI.

To report a vulnerability in this pack's content or tooling, open a GitHub security
advisory on this repository (or an issue if the report is not sensitive). For engine
vulnerabilities, use the [TAUT engine repository](https://github.com/yurgeno/taut).
