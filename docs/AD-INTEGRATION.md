# DS — Active Directory

| Setting | Value |
|---|---|
| FQDN | `grayhats.local` |
| NetBIOS | `GRAYHATS` |
| Domain/forest functional level | `Win2025` |
| Primary DC | `DS-dc01`, Windows Server 2025 — also the DNS server for the domain |
| Domain-joined hosts | `DS-dc01` (primary-dc), `DS-win01` (member) |
| Not domain-joined | `DS-caldera01`, `DS-artwin01`, `DS-splunk01` |

Same domain **name** as the sibling DE range (`grayhats.local`) but a fully
separate, isolated AD forest — no conflict, since the two ranges are on
different, non-routed networks.

AD + DNS promotion is handled entirely by Ludus's native `domain:` block —
no custom AD role in this repo. Functional level is `Win2025` here (unlike
the DE range's `WinThreshold`) because DC01 is genuinely Windows Server
2025 in this build, not a win2022 substitution — see `docs/VMS.md` for the
template risk and rationale.

## Accounts

| Account | Password var (overridable) | Default |
|---|---|---|
| `Administrator` (domain admin) | `ad_domain_admin_password` | `GrayHats-DSAdmin-2026!` |
| `grayhatsuser` (standard domain user) | `ad_domain_user_password` | `GrayHats-DSUser-2026!` |
| DSRM / Safe Mode | `ad_domain_safe_mode_password` | `GrayHats-DSSafeMode-2026!` |

## Splunk/Caldera agent discovery

`frack113.ludus_caldera_agent` auto-discovers `DS-caldera01` via Ludus's
`search_roles` filter — no manual IP wiring.

`p4t12ick.ludus_ar_windows` (Splunk UF) does **not** auto-discover —
`ludus_ar_windows_splunk_ip` must be a literal IP, filled in after
`createRange` (see `docs/VMS.md`). This is the one place in this repo's
config where an IP is hardcoded rather than resolved dynamically.
