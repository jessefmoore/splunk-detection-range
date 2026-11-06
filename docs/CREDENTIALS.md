# DS — Master Credential Sheet

**Keep this repo private.** Every credential below is a default committed to
`ds-range.yml` / `global_role_vars` for reproducibility, and is fully
overridable before deploy. Distinct from the sibling DE range's credentials
(no password reuse across ranges). Rotate before any public exposure.

## Active Directory (grayhats.local)

| Account | Password | Config key |
|---|---|---|
| `Administrator` (domain admin) | `GrayHats-DSAdmin-2026!` | `defaults.ad_domain_admin_password` |
| `grayhatsuser` (standard user) | `GrayHats-DSUser-2026!` | `defaults.ad_domain_user_password` |
| DSRM / Safe Mode | `GrayHats-DSSafeMode-2026!` | `defaults.ad_domain_safe_mode_password` |

## Caldera (DS-caldera01, http://\<ip\>:8888)

| Account | Password | Config key |
|---|---|---|
| `admin` | `GrayHats-DSCalderaAdmin-2026!` | `global_role_vars.ludus_caldera_admin_pwd` |
| `red` | `GrayHats-DSCalderaRed-2026!` | `global_role_vars.ludus_caldera_red_pwd` |
| `blue` | `GrayHats-DSCalderaBlue-2026!` | `global_role_vars.ludus_caldera_blue_pwd` |

## Splunk (DS-splunk01, https://\<ip\>:8000)

| Account | Password | Config key |
|---|---|---|
| `admin` | `GrayHats-DSSplunk-2026!` | `global_role_vars.ludus_ar_splunk_password` |
| Universal Forwarder | `GrayHats-DSSplunkUF-2026!` | `global_role_vars.ludus_ar_windows_password` |

## Ludus / Proxmox users

| Ludus userID | Role | Ludus login password | Proxmox login |
|---|---|---|---|
| `JM` | admin (you) | existing account, unchanged | existing account, unchanged |
| `DSTEAM1` | non-admin, console-only on `DS` | set at creation (see `docs/ACCESS-CONTROL.md`) | `detection-range-team-1-splunk` (realm pam) |

## Atomic Red Team (DS-artwin01)

No credentials — local install only (`j91321.atomic_red_team`), same as the
DE range.

## How to override before deploy

Every value above lives under `defaults:` or `global_role_vars:` in
`ds-range.yml` — edit the file before deploying. Nothing is hardcoded
inside any role.
