# DS — Splunk Detection Range (splunk-detection-range)

A Ludus-built purple-team range: Caldera red team operations against a small
`grayhats.local` AD environment, defended/detected with Splunk, plus a
standalone Atomic Red Team sandbox for authoring/validating detections.

This is range 2 of 2 planned detection ranges — the sibling
[`elastic-detection-range`](https://github.com/jessefmoore/elastic-detection-range)
is Elastic-only; this one is **Splunk-only**. Same shape, different SIEM.

- **Range ID:** `DS`
- **AD domain:** `grayhats.local` (NetBIOS `GRAYHATS`) — same name as the DE
  range's domain, fully isolated network, no conflict
- **Built and deployed via the Ludus MCP server** (no local `ludus` CLI used
  for this build; `scripts/*.sh` are provided for CLI-based operation later)

## Topology

| VLAN | Host | Purpose |
|---|---|---|
| 10 | DS-dc01 | AD DC + DNS (**Windows Server 2025** — see risk note below), Splunk UF + Caldera agent |
| 10 | DS-win01 | Windows 11 desktop, Splunk UF + Caldera agent |
| 10 | DS-caldera01 | Caldera C2 server (Ubuntu 24.04), targets DC01/WIN01 |
| 30 | DS-artwin01 | Atomic Red Team sandbox (Windows 11), standalone |
| 40 | DS-splunk01 | Splunk Enterprise (Ubuntu 24.04) |

Full details: [`docs/NETWORK.md`](docs/NETWORK.md), [`docs/VMS.md`](docs/VMS.md).

## Template strategy

Templates sourced from
[`badsectorlabs/ludus-source-bsl`](https://github.com/badsectorlabs/ludus-source-bsl)
where possible — `debian-13-x64-server-template` (router) and
`win2025-server-x64-tpm-template` (DC01).

**DC01 risk**: the sibling DE range hit this exact template forcing an
interactive Administrator password change on every clone, blocking WinRM,
and substituted win2022 instead. For this build, Windows Server 2025 was
requested explicitly after reading `ludus-source-bsl`'s actual
`Autounattend.xml` directly — it doesn't configure a forced password
change, so this is likely a Server 2025 runtime behavior rather than a
fixable config bug. See [`docs/VMS.md`](docs/VMS.md) for the full
diagnosis. If DS-dc01 hits the same symptom again, the plan is to stop and
ask rather than silently substitute.

## Roles

| Role | Source | Purpose |
|---|---|---|
| `p4t12ick.ludus_ar_splunk` | Galaxy (3rd-party) | Splunk Enterprise server |
| `p4t12ick.ludus_ar_windows` | Galaxy (3rd-party) | Splunk Universal Forwarder + Sysmon/auditing on Windows endpoints (also bundles Atomic Red Team) |
| `frack113.ludus_caldera_server` | Galaxy (3rd-party) | Caldera C2 server |
| `frack113.ludus_caldera_agent` | Galaxy (3rd-party) | Caldera Sandcat agent |
| `j91321.atomic_red_team` | Galaxy (3rd-party) | Invoke-AtomicRedTeam framework + atomics |
| `art_psmodule_prereq` | custom, `roles/art_psmodule_prereq` | Reused from the DE range — fixes a PowerShellGet incompatibility on win11-22h2 |

## Deploy

**Important**: `p4t12ick.ludus_ar_windows` has no auto-discovery (unlike the
Elastic/Caldera roles) — `global_role_vars.ludus_ar_windows_splunk_ip` in
`ds-range.yml` must be filled in with `DS-splunk01`'s real IP (known only
after the range is created) before deploying.

```bash
# 1. Install roles (idempotent to re-run)
scripts/install-roles.sh

# 2. Create the range first to learn the IP scheme, fill in
#    ludus_ar_windows_splunk_ip in ds-range.yml, THEN:
scripts/deploy.sh DS

# 3. Create team access
scripts/create-team-user.sh DSTEAM1 "Detection Range Team 1 - Splunk" dsteam1@grayhats.local DS
```

## Docs

- [`docs/NETWORK.md`](docs/NETWORK.md) — VLANs, IP scheme, routing policy
- [`docs/VMS.md`](docs/VMS.md) — full VM inventory, specs, role sourcing, DC01 template risk
- [`docs/AD-INTEGRATION.md`](docs/AD-INTEGRATION.md) — domain, accounts, agent discovery
- [`docs/ACCESS-CONTROL.md`](docs/ACCESS-CONTROL.md) — team user / Proxmox console-only access
- [`docs/CREDENTIALS.md`](docs/CREDENTIALS.md) — master credential sheet
- [`docs/VALIDATION.md`](docs/VALIDATION.md) — post-deploy validation checklist

## Status

- [x] Range `DS` created (rangeNumber 31, IP scheme `10.31.<VLAN>.<octet>`)
- [x] Roles confirmed installed on the Ludus server
- [x] Team user `DSTEAM1` created, assigned console-only access to `DS`
- [x] Config pushed (`ludus_ar_windows_splunk_ip` filled in as `10.31.40.35`)
- [ ] **Not yet deployed** — `deployRange` has not been run yet.
