# DS — VM Inventory

| Hostname | VLAN | IP | Template | Specs | Ansible roles |
|---|---|---|---|---|---|
| **DS-dc01** | 10 | 10.\<range_number\>.10.31 | `win2025-server-x64-tpm-template` | 8GB RAM (min 4), 4 vCPU | `p4t12ick.ludus_ar_windows`, `frack113.ludus_caldera_agent` |
| **DS-win01** | 10 | 10.\<range_number\>.10.32 | `win11-22h2-x64-enterprise-template` | 6GB RAM (min 3), 2 vCPU | `p4t12ick.ludus_ar_windows`, `frack113.ludus_caldera_agent` |
| **DS-caldera01** | 10 | 10.\<range_number\>.10.33 | `ubuntu-24.04-x64-server-template` | 6GB RAM (min 3), 4 vCPU | `frack113.ludus_caldera_server` (auto-pulls `geerlingguy.docker`) |
| **DS-artwin01** | 30 | 10.\<range_number\>.30.34 | `win11-22h2-x64-enterprise-template` | 4GB RAM (min 2), 2 vCPU | `art_psmodule_prereq` (custom), `j91321.atomic_red_team` |
| **DS-splunk01** | 40 | 10.\<range_number\>.40.35 | `ubuntu-24.04-x64-server-template` | 12GB RAM (min 6), 4 vCPU | `p4t12ick.ludus_ar_splunk` |

This range mirrors the sibling `elastic-detection-range` (range `DE`) exactly
in shape — same VLAN layout, same VM count, same Caldera/ART setup — with
the Elastic stack swapped for Splunk.

## Template sourcing: `ludus-source-bsl` where possible

Per project convention, templates are sourced from
[`badsectorlabs/ludus-source-bsl`](https://github.com/badsectorlabs/ludus-source-bsl)
when available: `debian-13-x64-server-template` (router) and
`win2025-server-x64-tpm-template` (DC01) both come from that repo's
`templates/` directory.

## DC01 template risk: `win2025-server-x64-tpm-template`

On the DE range build, this exact template forced an interactive
Administrator password change on every fresh clone, blocking WinRM before
AD promotion could run — confirmed twice, identically, via Proxmox console
and Ansible logs (`DE-dc01: unreachable=1`). That build substituted
`win2022-server-x64-template` instead.

For this build, the user explicitly asked to use Windows Server 2025 for
DC01 anyway, informed by reading `ludus-source-bsl`'s actual
`templates/win2025-server-x64-tpm/Autounattend.xml` directly:
- It does **not** set `<PasswordExpires>` or any forced-change flag.
- `<AutoLogon>` is configured for an account named `localuser`, not
  `Administrator`.
- So the forced password prompt observed on DE-dc01 is most likely a
  Windows Server 2025 **runtime** password-complexity re-validation against
  the weak unattend-set password ("password"), not a simple unattend
  misconfiguration — not something fixable via range-config alone.
- Bad Sector Labs' own reference blueprint (`blueprints/ad-elastic-range` in
  `ludus-source-bsl`) uses `win2022-server-x64-template` for its DC despite
  having `win2025-server-x64-tpm-template` available — a signal (not a
  guarantee) that it isn't validated for unattended DC promotion.

**If DS-dc01 hits the same `unreachable` symptom again**: stop and report
rather than silently substituting win2022 — this is now a deliberate choice,
not a default, so the user should decide the next step (retry patiently,
attempt a password-reset workaround, or substitute).

## Role sourcing (confirmed installed on this server, 2026-11-06)

| Role | Source | Status |
|---|---|---|
| `p4t12ick.ludus_ar_splunk` | Ansible Galaxy (3rd-party) | already installed, v1.1.3 |
| `p4t12ick.ludus_ar_windows` | Ansible Galaxy (3rd-party) | already installed, v1.1.2 |
| `frack113.ludus_caldera_server` / `_agent` | Ansible Galaxy (3rd-party) | reused from DE range |
| `j91321.atomic_red_team` | Ansible Galaxy (3rd-party) | reused from DE range |
| `art_psmodule_prereq` | custom, `roles/art_psmodule_prereq` | reused from DE range (user-scoped on this server, no reinstall needed) |

## Splunk UF IP wiring (no auto-discovery)

Unlike `badsectorlabs.ludus_elastic_agent` (which auto-discovers its server
via Ludus's `search_roles` filter), `p4t12ick.ludus_ar_windows` needs
`ludus_ar_windows_splunk_ip` as a **literal IP address** — confirmed from
the role's actual `defaults/main.yml` (default value `10.2.20.1`, clearly a
placeholder meant to be overridden). No Ludus-native auto-discovery or
`depends_on`-equivalent exists for this value, so the build process is:
1. `createRange` first, to learn the auto-assigned range number.
2. Compute `DS-splunk01`'s real IP (`10.<range_number>.40.35`).
3. Fill that IP into `global_role_vars.ludus_ar_windows_splunk_ip` in
   `ds-range.yml` before pushing config / deploying.

## Purpose of each host

- **DS-dc01** — grayhats.local primary domain controller + DNS. Carries both
  the Splunk Universal Forwarder (detection) and the Caldera Sandcat agent
  (attack surface) — a red team target that also ships telemetry to Splunk.
- **DS-win01** — domain-joined Windows 11 desktop. Same dual-agent setup.
- **DS-caldera01** — Caldera C2/adversary-emulation server, targets DC01 and
  WIN01 only.
- **DS-artwin01** — standalone (not domain-joined) Atomic Red Team sandbox,
  mirroring DE-artwin01. Note `p4t12ick.ludus_ar_windows` on DC01/WIN01
  already bundles its own ART install as a side effect of the UF setup —
  this dedicated box exists for shape-parity with the DE range and to give
  engineers an isolated place to author/validate atomics first.
- **DS-splunk01** — Splunk Enterprise. Receives Universal Forwarder data
  from DC01/WIN01; this is where detections are built and searches run.
