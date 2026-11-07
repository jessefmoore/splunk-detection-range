# DS — VM Inventory

| Hostname | VLAN | IP | Template | Specs | Ansible roles |
|---|---|---|---|---|---|
| **DS-dc01** | 10 | 10.31.10.31 | `win2025-server-x64-tpm-template` | 8GB RAM (min 4), 4 vCPU | `p4t12ick.ludus_ar_windows`, `frack113.ludus_caldera_agent` |
| **DS-win01** | 10 | 10.31.10.32 | `win11-22h2-x64-enterprise-template` | 6GB RAM (min 3), 2 vCPU | `p4t12ick.ludus_ar_windows`, `frack113.ludus_caldera_agent` |
| **DS-caldera01** | 10 | 10.31.10.33 | `ubuntu-24.04-x64-server-template` | 6GB RAM (min 3), 4 vCPU | `frack113.ludus_caldera_server` (auto-pulls `geerlingguy.docker`) |
| **DS-artwin01** | 30 | 10.31.30.34 | `win11-22h2-x64-enterprise-template` | 4GB RAM (min 2), 2 vCPU | `art_psmodule_prereq` (custom), `j91321.atomic_red_team` |
| **DS-splunk01** | 40 | 10.31.40.35 | `ubuntu-24.04-x64-server-template` | 12GB RAM (min 6), 4 vCPU | `p4t12ick.ludus_ar_splunk` |

This range mirrors the sibling `elastic-detection-range` (range `DE`) exactly
in shape — same VLAN layout, same VM count, same Caldera/ART setup — with
the Elastic stack swapped for Splunk.

## Template sourcing: `ludus-source-bsl` where possible

Per project convention, templates are sourced from
[`badsectorlabs/ludus-source-bsl`](https://github.com/badsectorlabs/ludus-source-bsl)
when available: `debian-13-x64-server-template` (router) and
`win2025-server-x64-tpm-template` (DC01) both come from that repo's
`templates/` directory.

## DC01 template resolution: `win2025-server-x64-tpm-template` — RESOLVED

**Result: win2025-server-x64-tpm-template now works, after a fresh rebuild.**
`DS-dc01` promoted cleanly, `DS-win01` joined the domain without issue, and
the full deploy finished with zero failed tasks across every host.

History of this investigation:
1. On the DE range build, this exact template forced an interactive
   Administrator password change on every fresh clone, blocking WinRM
   before AD promotion could run — confirmed twice, identically, via
   Proxmox console and Ansible logs (`DE-dc01: unreachable=1`). That build
   substituted `win2022-server-x64-template` instead.
2. For this build, the user asked to use Windows Server 2025 for DC01
   anyway. Reading `ludus-source-bsl`'s actual `Autounattend.xml` directly
   showed no `PasswordExpires` or forced-change flag, and `AutoLogon`
   configured for `localuser` not `Administrator` — ruling out a simple
   unattend misconfiguration as the cause.
3. First DS attempt against the **existing, previously-built copy** of this
   template on the Ludus server hit the identical `unreachable` symptom —
   suggesting either a genuinely broken existing build, or a real Server
   2025 runtime issue.
4. Rebuilt the template from scratch: `deleteTemplate` (which turned out to
   remove the whole definition, not just the built image — see
   `docs/REBUILD-NOTES.md`), re-registered it from a fresh `git clone` of
   `ludus-source-bsl`'s `templates/win2025-server-x64-tpm/` via
   `addTemplateFromTar`, then `buildTemplates`. First rebuild attempt failed
   on an unrelated WinRM/Windows-Update-polling fault during the template's
   *own* build-time provisioning (`ansible/windows_update_security_updates.yml`);
   retried and it built clean.
5. Redeployed `DS` against the freshly rebuilt template: **DC01 promoted
   successfully this time**, `DS-win01` joined the domain, and the entire
   deploy completed with 0 failures across all 6 hosts.

**Conclusion**: the template definition itself (current `ludus-source-bsl`
source) is fine. The DE range's failure and this range's *first* attempt
were most likely caused by a stale/corrupted previously-built image on this
specific Ludus server, not a flaw in the template source or a Windows
Server 2025 runtime limitation. If this template ever misbehaves again on
this server, a fresh rebuild (not a substitution) should be the first thing
tried — see `docs/REBUILD-NOTES.md` for the exact procedure.

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
2. Compute `DS-splunk01`'s real IP (`10.31.40.35`).
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
