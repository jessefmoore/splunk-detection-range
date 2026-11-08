# DS — Splunk Detection Range (splunk-detection-range)

A Ludus-built purple-team range: Caldera red team operations against a small
`grayhats.local` AD environment, defended/detected with Splunk, plus a
standalone Atomic Red Team Windows11 to augment red team operations.

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
| `art_psmodule_prereq` | custom, `roles/art_psmodule_prereq` | Reused from the DE range — fixes a PowerShellGet incompatibility on win11-22h2 |

## Docs

- [`docs/NETWORK.md`](docs/NETWORK.md) — VLANs, IP scheme, routing policy
- [`docs/VMS.md`](docs/VMS.md) — full VM inventory, specs, role sourcing, DC01 template risk
- [`docs/AD-INTEGRATION.md`](docs/AD-INTEGRATION.md) — domain, accounts, agent discovery
- [`docs/ACCESS-CONTROL.md`](docs/ACCESS-CONTROL.md) — team user / Proxmox console-only access
- [`docs/CREDENTIALS.md`](docs/CREDENTIALS.md) — master credential sheet
- [`docs/VALIDATION.md`](docs/VALIDATION.md) — post-deploy validation checklist
- [`docs/REBUILD-NOTES.md`](docs/REBUILD-NOTES.md) — runbook for rebuilding a `ludus-source-bsl` template from scratch

- **Range ID:** `DS`
- **AD domain:** `grayhats.local` (NetBIOS `GRAYHATS`), fully isolated network
- **Built and deployed via the Ludus MCP server** (no local `ludus` CLI used
  for this build; `scripts/*.sh` are provided for CLI-based operation later)

## Quick Start to install on your other Ludus Server

Deploying this range from scratch (fresh Ludus server, or after a teardown
of `DS`) takes these steps, in order. 

Commands shown both ways — via the
Ludus MCP server (what this repo was actually built with) and the
equivalent `ludus` CLI command, for whichever you're using.

**1. Confirm/build the templates this range needs.**
`win2025-server-x64-tpm-template`, `win11-22h2-x64-enterprise-template`,
`ubuntu-24.04-x64-server-template`, `debian-13-x64-server-template`
(router). Check with `getTemplates` — if any show `built: false`:
```bash
scripts/build-templates.sh                      # CLI
# or: mcp__ludus__call_ludus_api buildTemplates, body {"templates": [...]}
```
If `win2025-server-x64-tpm-template` ever misbehaves (DC01 goes
`unreachable` during AD promotion), rebuild it fresh before assuming it's
broken — see [`docs/REBUILD-NOTES.md`](docs/REBUILD-NOTES.md). That fixed
it on this exact server; the template source itself is fine.

**2. Install the roles.**
```bash
scripts/install-roles.sh
```
This installs the 4 third-party Galaxy roles. `art_psmodule_prereq`
(custom) needs a one-time tarball upload if this is a server that's never
seen it — see [`roles/ROLE_CONVENTIONS.md`](roles/ROLE_CONVENTIONS.md).

**3. Create the range — then learn its IP scheme.**
```bash
ludus range create --name "Splunk Detection Range" -r DS
ludus range list -r DS          # note the rangeNumber, e.g. 31
```
`p4t12ick.ludus_ar_windows` (Splunk UF) has **no auto-discovery** — unlike
the Elastic/Caldera roles, it needs a literal IP. So this step has to
happen *before* you can finalize the config.

**4. Fill in the Splunk server's real IP.**
Edit `ds-range.yml`:
```yaml
global_role_vars:
  ludus_ar_windows_splunk_ip: "10.<range_number>.40.35"   # DS-splunk01
```

**5. Push config and deploy.**
```bash
scripts/deploy.sh DS
```
Expect 1-3 hours. Deploys are idempotent — safe to re-run
`ludus range deploy -r DS` if it errors on a transient issue (a known one:
fresh AD builds can hit an "ADWS not up yet" blip on the first pass, see
[`docs/VALIDATION.md`](docs/VALIDATION.md)).

**6. Create team access.**
```bash
scripts/create-team-user.sh DSTEAM1 "Detection Range Team 1 - Splunk" dsteam1@grayhats.local DS
```

**7. Validate.**
Walk [`docs/VALIDATION.md`](docs/VALIDATION.md) — AD/DNS, Splunk forwarder
health (`https://<splunk-ip>:8000`, creds in
[`docs/CREDENTIALS.md`](docs/CREDENTIALS.md)), Caldera, Atomic Red Team,
then the end-to-end purple-team loop.

## Gotchas if you had preexisting templates in Ludus Server and not BSL

**1. Confirm your templates are sourced from `ludus-source-bsl`.**
This range needs `win2025-server-x64-tpm-template`,
`win11-22h2-x64-enterprise-template`, `ubuntu-24.04-x64-server-template`, and
`debian-13-x64-server-template`. The first and last of those are templated
from [`badsectorlabs/ludus-source-bsl`](https://github.com/badsectorlabs/ludus-source-bsl)
in this build — see "Template strategy" below. If any are missing, build
them:
```bash
scripts/build-templates.sh
```
**If you already have one of these templates built from somewhere other
than the current `ludus-source-bsl` source** — the stock Ludus template
repo, or an older local checkout of `ludus-source-bsl` predating a given
template's definition — rebuild it fresh before trusting it. A stale image
is exactly what caused DC01 to hang on an interactive Administrator password
prompt during this range's own build (see "Template strategy" below and
[`docs/REBUILD-NOTES.md`](docs/REBUILD-NOTES.md) for the full
`deleteTemplate` → `addTemplateFromTar` → `buildTemplates` runbook).


# When creating a Blueprint live on server

**1. Create Blueprint from existing range config file
```bash
ludus blueprint create --id splunk-detection-range --config ./ds-range.yml
```

**2. Change configs if you need
```bash
ludus blueprint config edit splunk-detection-range
```

**3. Make sure Blueprint, range-config and requirements.yml are in the repo
Go to repo directory and 
```bash
mkdir blueprints
```
Then go to server where you are creating this Ludus Blueprint if not already
Copy the files you need over to your repo location.
Side note: The Kali is where I was building my Splunk-Detection-range with Claude, so I had to move files over there.
```bash
scp /opt/ludus/blueprints/snsqh8yg8fway0o/range-config.yml kali@10.2.10.13:/tmp
```
Then the requirements.yml
```bash
scp /opt/ludus/blueprints/snsqh8yg8fway0o/requirements.yml kali@10.2.10.13:/tmp
```
Move to the repo
```bash
splunk-detection-range/blueprints/splunk-detection-range
```
Create the blueprint.yml by hand
```bash
manifest_version: 1
id: splunk-detection-range
name: "Splunk Detection Range"
description: "Purple-team range: Caldera red team ops against windows"
version: 1.0.0
tags: [ad, splunk, caldera, atomic-red-team, purple-team, detection]
min_ludus_version: 2.3.10
config: range-config.yml
```


# Share blueprint with specific users or groups on this server.**
```bash
ludus blueprint share user  splunk-detection-range <userID...>
ludus blueprint share group splunk-detection-range <groupName...>
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
ludus ansible role add -d splunk-detection-range/roles/art_psmodule_prereq --force
```

Given that caveat, cloning the repo directly is the simpler
path whenever git access is available.

## License

[MIT](LICENSE) — use freely, no warranty.


## Template strategy

Templates sourced from
[`badsectorlabs/ludus-source-bsl`](https://github.com/badsectorlabs/ludus-source-bsl)
where possible — `debian-13-x64-server-template` (router) and
`win2025-server-x64-tpm-template` (DC01).

**DC01 resolved**: the sibling DE range hit this exact template forcing an
interactive Administrator password change on every clone, blocking WinRM,
and substituted win2022 instead. This range's first attempt (against the
server's existing, previously-built copy of the template) hit the
identical symptom. A fresh rebuild from the current `ludus-source-bsl`
source (`deleteTemplate` → re-register via `addTemplateFromTar` →
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
- [x] Config pushed (`ludus_ar_windows_splunk_ip` filled in as `10.31.40.35`)
- [x] **Deployed successfully** — all 5 VMs + router up, `rangeState: SUCCESS`,
      zero failed tasks across every host in the final run. `win2025-server-x64-tpm-template`
      required a fresh rebuild first (see `docs/VMS.md`/`docs/REBUILD-NOTES.md`)
      but DC01 promoted cleanly once rebuilt. Splunk UF confirmed installed
      on DS-dc01/DS-win01, Splunk Enterprise + add-ons on DS-splunk01, ART on
      DS-artwin01. Live confirmation of forwarder status: Splunk web UI at
      `https://10.31.40.35:8000` (creds in `docs/CREDENTIALS.md`).

## YouTube video of me walking thru this. It's mostly did the video in one sitting, so excuse the errors.
## Walkthrough.
By [@jessefmoore](https://x.com/jessefmore) Helping others do this too that like video walkthrus.

[![Video Title](https://img.youtube.com/vi/6niWSUw9MoE/hqdefault.jpg)](https://youtu.be/6niWSUw9MoE)

## Recognition and Contributions
- [Bad Sector Labs](https://twitter.com/badsectorlabs) for making an awesome tool to easily deploy and purge lab environments via proxmox. 

