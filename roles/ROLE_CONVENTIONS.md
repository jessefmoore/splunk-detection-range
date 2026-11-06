# roles/ — conventions for this repo

## `art_psmodule_prereq`
Reused as-is from the sibling `elastic-detection-range` repo (same fix:
updates NuGet/PowerShellGet on `win11-22h2-x64-enterprise-template` before
`j91321.atomic_red_team` runs on `DS-artwin01`). Already installed
user-scoped on this Ludus server from the DE range build — no reinstall
needed here. If deploying fresh on a different server:
```bash
ludus ansible role add -d roles/art_psmodule_prereq --force
```

If another custom role becomes necessary, follow the same shape: one role
per concern, variables namespaced with the role's name, defaults in
`defaults/main.yml`, nothing hardcoded that can't be overridden via
`role_vars`/`global_role_vars`.
