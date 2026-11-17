# ansible/ — vendored roles for this source

## `roles/art_psmodule_prereq`
Custom role, vendored directly in this source (not a Galaxy dependency).
Fixes a PowerShellGet incompatibility on `win11-22h2-x64-enterprise-template`
before `j91321.atomic_red_team` runs on `DS-artwin01` — the template ships an
inbox PowerShellGet that doesn't support the `-AcceptLicense` parameter
`community.windows.win_psmodule` passes to `Install-Module`.

Installed automatically when this source is added
(`ludus source add ... --all`) or synced. To install it manually instead:
```bash
ludus ansible role add -d ansible/roles/art_psmodule_prereq --force
```

If another custom role becomes necessary, follow the same shape: one role
per concern, variables namespaced with the role's name, defaults in
`defaults/main.yml`, nothing hardcoded that can't be overridden via
`role_vars`/`global_role_vars`.
