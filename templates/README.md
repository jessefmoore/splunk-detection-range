# templates/ — Packer templates for this source

This range needs 4 templates. Only 2 are vendored here — the other 2 ship
with every Ludus install, no source or build step needed beyond what's
already on your server.

| Template | Status |
|---|---|
| `win11-22h2-x64-enterprise-template` | Stock Ludus core — nothing to do |
| `debian-13-x64-server-template` | Stock Ludus core — nothing to do |
| `win2025-server-x64-tpm-template` | **Vendored** in [`win2025-server-x64-tpm/`](win2025-server-x64-tpm/) |
| `ubuntu-24.04-x64-server-template` | **Vendored** in [`ubuntu-24.04-x64-server/`](ubuntu-24.04-x64-server/) |

`ludus source add https://github.com/jessefmoore/splunk-detection-range --all`
registers the vendored templates along with the blueprint and roles — build
them with `ludus templates build`.

## Provenance

The two vendored directories are unmodified copies from
[`badsectorlabs/ludus-source-bsl`](https://github.com/badsectorlabs/ludus-source-bsl)
(commit `994345d`), licensed AGPL-3.0-or-later — see each directory's
`NOTICE.md` and [`LICENSE-AGPL-3.0-vendored.txt`](LICENSE-AGPL-3.0-vendored.txt).
That license applies only to these two vendored directories; the rest of
this repo is [MIT](../LICENSE). They're copies, not a live link — if
upstream ships a security-relevant update (e.g. a changed ISO URL/checksum),
this copy needs a manual re-sync.
