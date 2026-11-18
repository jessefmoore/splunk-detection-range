# DS — Splunk Detection Range (splunk-detection-range)

A Ludus-built purple-team range: Caldera red team operations against a small
`grayhats.local` AD environment, defended/detected with Splunk, plus a
standalone Atomic Red Team Windows11 to augment red team operations.

This repo is a **[Ludus source](https://docs.ludus.cloud/docs/using-ludus/sources)**
— add it to your Ludus server and deploy the whole range in 3 commands.

## Topology

| VLAN | Host | Purpose |
|---|---|---|
| 10 | DS-dc01 | AD DC + DNS (**Windows Server 2025**, confirmed working — see below), Splunk UF + Caldera agent |
| 10 | DS-win01 | Windows 11 desktop, Splunk UF + Caldera agent |
| 10 | DS-caldera01 | Caldera C2 server (Ubuntu 24.04), targets DC01/WIN01 |
| 30 | DS-artwin01 | Atomic Red Team sandbox (Windows 11), standalone |
| 40 | DS-splunk01 | Splunk Enterprise (Ubuntu 24.04) |

Full details: [`docs/NETWORK.md`](docs/NETWORK.md), [`docs/VMS.md`](docs/VMS.md).

## Roles

| Role | Source | Purpose |
|---|---|---|
| `p4t12ick.ludus_ar_splunk` | Galaxy (3rd-party) | Splunk Enterprise server |
| `p4t12ick.ludus_ar_windows` | Galaxy (3rd-party) | Splunk Universal Forwarder + Sysmon/auditing on Windows endpoints (also bundles Atomic Red Team) |
| `frack113.ludus_caldera_server` | Galaxy (3rd-party) | Caldera C2 server |
| `frack113.ludus_caldera_agent` | Galaxy (3rd-party) | Caldera Sandcat agent |
| `j91321.atomic_red_team` | Galaxy (3rd-party) | Invoke-AtomicRedTeam framework + atomics |
| `art_psmodule_prereq` | custom, vendored at `ansible/roles/art_psmodule_prereq` | Fixes a PowerShellGet incompatibility on win11-22h2 before Atomic Red Team runs |

## Docs

- [`docs/NETWORK.md`](docs/NETWORK.md) — VLANs, IP scheme, routing policy
- [`docs/VMS.md`](docs/VMS.md) — full VM inventory, specs, role sourcing, DC01 template risk
- [`docs/AD-INTEGRATION.md`](docs/AD-INTEGRATION.md) — domain, accounts, agent discovery
- [`docs/ACCESS-CONTROL.md`](docs/ACCESS-CONTROL.md) — team user / Proxmox console-only access
- [`docs/CREDENTIALS.md`](docs/CREDENTIALS.md) — master credential sheet
- [`docs/VALIDATION.md`](docs/VALIDATION.md) — post-deploy validation checklist
- [`docs/REBUILD-NOTES.md`](docs/REBUILD-NOTES.md) — runbook for rebuilding a template from scratch
- [`ansible/README.md`](ansible/README.md) — vendored custom role conventions
- [`templates/README.md`](templates/README.md) — vendored Packer templates, provenance, licensing

- **Range ID:** `DS`
- **AD domain:** `grayhats.local` (NetBIOS `GRAYHATS`), fully isolated network

## Quick Start — deploy on your Ludus server

No other sources required — this one is fully self-contained (blueprint,
roles, and the 2 non-stock Packer templates are all vendored here; the
other 2 templates ship with every Ludus install). The 3 commands:
```bash
ludus source add https://github.com/jessefmoore/splunk-detection-range --all
ludus blueprint apply <sourceID>/splunk-detection-range
ludus range deploy
```
`<sourceID>` isn't predictable up front — after `source add`, run
`ludus source list` and copy the value from the `SOURCE ID` column for
"Splunk Detection Range" into the `blueprint apply` command above.

Before `range deploy`, build any vendored templates that aren't already on
your server (`ludus templates list` to check):
```bash
ludus templates build
```

Expect 1-3 hours for all VMs + AD + roles. Deploys are idempotent — safe to
re-run `ludus range deploy` if it errors on a transient issue (a known one:
fresh AD builds can hit an "ADWS not up yet" blip on the first pass, see
[`docs/VALIDATION.md`](docs/VALIDATION.md)).

`ludus source add --all` installs this blueprint's roles automatically
(3 Galaxy roles + the vendored `art_psmodule_prereq`), and the
`ludus_ar_windows_splunk_ip` value needed by the Splunk Universal Forwarder
role is templated with `{{ range_second_octet }}` in `range-config.yml` —
no manual IP edit required, unlike earlier revisions of this repo.

**Optional — team access, once deployed:**
```bash
scripts/create-team-user.sh DSTEAM1 "Detection Range Team 1 - Splunk" dsteam1@grayhats.local DS
```

**Validate:** walk [`docs/VALIDATION.md`](docs/VALIDATION.md) — AD/DNS,
Splunk forwarder health (`https://<splunk-ip>:8000`, creds in
[`docs/CREDENTIALS.md`](docs/CREDENTIALS.md)), Caldera, Atomic Red Team,
then the end-to-end purple-team loop.

### Alternative: CLI scripts, no blueprint

If you'd rather drive this with the `ludus` CLI directly instead of
`ludus source add` / `blueprint apply` (e.g. scripting against the raw
`range-config.yml`), `scripts/*.sh` cover the same steps:
```bash
scripts/build-templates.sh   # only if templates aren't already built
scripts/install-roles.sh     # installs the Galaxy roles + the custom one
scripts/deploy.sh DS         # pushes blueprints/splunk-detection-range/range-config.yml and deploys
```

## Gotchas if you already have these templates built from elsewhere

This range needs 4 templates: `win11-22h2-x64-enterprise-template` and
`debian-13-x64-server-template` ship with every Ludus install (nothing to
do); `win2025-server-x64-tpm-template` and `ubuntu-24.04-x64-server-template`
are vendored in this repo under [`templates/`](templates/) — `ludus source
add --all` registers them, then:
```bash
ludus templates build
```
**If you already have `win2025-server-x64-tpm-template` or
`ubuntu-24.04-x64-server-template` built from somewhere else** — the stock
Ludus template catalog, `ludus-source-bsl` directly, or an older build
predating this repo's vendored copy — rebuild it fresh before trusting it.
A stale image is exactly what caused DC01 to hang on an interactive
Administrator password prompt during this range's own build (see "Template
strategy" below and [`docs/REBUILD-NOTES.md`](docs/REBUILD-NOTES.md) for the
full `deleteTemplate` → `addTemplateFromTar` → `buildTemplates` runbook).

## Maintaining this blueprint

The blueprint under `blueprints/splunk-detection-range/` (`blueprint.yml`,
`range-config.yml`, `requirements.yml`, `README.md`) is the canonical,
source-of-truth config — edit it directly rather than a separate top-level
copy. To test local edits against a live Ludus server before committing:
```bash
ludus blueprint create --id splunk-detection-range --config blueprints/splunk-detection-range/range-config.yml
ludus blueprint config edit splunk-detection-range   # or edit the file and re-create
```

### Sharing to a different Ludus server (no git access there)

If the other admin can't `git clone`, export a tarball instead — but note
it still drops the custom role and Packer templates, so they'll need a copy
of this repo regardless:
```bash
ludus blueprint export splunk-detection-range -o splunk-detection-range.tar.gz
# --- on the other server ---
ludus blueprint create --import splunk-detection-range.tar.gz
git clone https://github.com/jessefmoore/splunk-detection-range.git
ludus ansible role add -d splunk-detection-range/ansible/roles/art_psmodule_prereq --force
```

Given that caveat, `ludus source add` (which pulls everything, including
the vendored role, in one step) is the simpler path whenever git access is
available — see Quick Start above.

## License

[MIT](LICENSE) for this repo, except the two vendored template directories
under [`templates/`](templates/) (`win2025-server-x64-tpm/`,
`ubuntu-24.04-x64-server/`), which carry upstream's
[AGPL-3.0-or-later](templates/LICENSE-AGPL-3.0-vendored.txt) — see
[`templates/README.md`](templates/README.md).

## Template strategy

4 templates needed; 2 ship with every Ludus install
(`win11-22h2-x64-enterprise-template`, `debian-13-x64-server-template`,
no source dependency). The other 2 —
`win2025-server-x64-tpm-template` (DC01) and `ubuntu-24.04-x64-server-template`
(CALDERA01/SPLUNK01) — originate from
[`badsectorlabs/ludus-source-bsl`](https://github.com/badsectorlabs/ludus-source-bsl)
and are vendored directly in this repo's [`templates/`](templates/) so this
source needs no external `ludus source add`. See `templates/README.md` for
provenance (pinned upstream commit) and the AGPL notice.

**DC01 resolved**: the sibling DE range hit this exact template forcing an
interactive Administrator password change on every clone, blocking WinRM,
and substituted win2022 instead. This range's first attempt (against the
server's existing, previously-built copy of the template) hit the
identical symptom. A fresh rebuild from `ludus-source-bsl`'s source
(`deleteTemplate` → re-register via `addTemplateFromTar` →
`buildTemplates`) fixed it — DC01 promoted cleanly and the full deploy
finished with **zero failed tasks across all 6 hosts**. Conclusion: the
template source itself is fine; the failures were a stale/corrupted
previously-built image on this specific server, not a Windows Server 2025
limitation. See [`docs/VMS.md`](docs/VMS.md) for the full investigation and
[`docs/REBUILD-NOTES.md`](docs/REBUILD-NOTES.md) for the exact rebuild
runbook (including two non-obvious gotchas: `deleteTemplate` removes the
whole definition, not just the image, and `addTemplateFromTar` requires a
plain uncompressed `.tar`, not `.tgz`).

## Status

- [x] Range `DS` created (rangeNumber 31, IP scheme `10.31.<VLAN>.<octet>`)
- [x] Roles confirmed installed on the Ludus server
- [x] Team user `DSTEAM1` created, assigned console-only access to `DS`
- [x] Config pushed (`ludus_ar_windows_splunk_ip` now templated with
      `{{ range_second_octet }}`, no manual fill-in needed)
- [x] **Deployed successfully** — all 5 VMs + router up, `rangeState: SUCCESS`,
      zero failed tasks across every host in the final run. `win2025-server-x64-tpm-template`
      required a fresh rebuild first (see `docs/VMS.md`/`docs/REBUILD-NOTES.md`)
      but DC01 promoted cleanly once rebuilt. Splunk UF confirmed installed
      on DS-dc01/DS-win01, Splunk Enterprise + add-ons on DS-splunk01, ART on
      DS-artwin01. Live confirmation of forwarder status: Splunk web UI at
      `https://10.31.40.35:8000` (creds in `docs/CREDENTIALS.md`).
- [x] Packaged as a proper [Ludus source](https://docs.ludus.cloud/docs/using-ludus/sources)
      (`source.yml`, `blueprints/`, `ansible/roles/`, `templates/`) —
      deployable by others via `ludus source add` in 3 commands.
- [x] Fully self-contained: the 2 non-stock templates (`win2025-server-x64-tpm-template`,
      `ubuntu-24.04-x64-server-template`) are vendored in `templates/` —
      no external `ludus source add` needed for anything this range uses.

## YouTube video of me walking thru this. It's mostly did the video in one sitting, so excuse the errors.
## Walkthrough.
By [@jessefmoore](https://x.com/jessefmore) Helping others do this too that like video walkthrus.

[![Video Title](https://img.youtube.com/vi/6niWSUw9MoE/hqdefault.jpg)](https://youtu.be/6niWSUw9MoE)

## Recognition and Contributions
- [Bad Sector Labs](https://twitter.com/badsectorlabs) for making an awesome tool to easily deploy and purge lab environments via proxmox.
