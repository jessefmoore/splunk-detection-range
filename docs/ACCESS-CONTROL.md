# DS Range — Proxmox Access Control (console-only team access)

## Requirement
A non-admin user must be able to use the Proxmox GUI but only **see and open
the console** of the VMs in the `DS` range — nothing else.

## How Ludus satisfies this
Every Ludus user gets a Proxmox account (realm `pam`) scoped to the resource
pool of the range(s) assigned to them. A non-admin user:
- logs into the Proxmox web GUI at `https://<proxmox-host>:8006`,
- sees only their assigned range's pool (`DS`),
- can open each VM's noVNC console,
- cannot build templates, touch other ranges, or get a host shell.

## What was set up for this range

```
Ludus user     : DSTEAM1  ("Detection Range Team 1 - Splunk")  — NON-ADMIN
Proxmox login  : detection-range-team-1-splunk  (realm: pam)
Range assigned : DS
```

Created via the Ludus MCP server (same pattern as the DE range's
`DETEAM1`):
- `addUser` → `{"name":"Detection Range Team 1 - Splunk","userID":"DSTEAM1","isAdmin":false,"email":"dsteam1@grayhats.local"}`
- `assignRangeToUser` → `DSTEAM1` / `DS`

Equivalent CLI (see `scripts/create-team-user.sh`):
```bash
ludus users add --name "Detection Range Team 1 - Splunk" --userid DSTEAM1 --email dsteam1@grayhats.local
ludus range assign DSTEAM1 DS
```

See `docs/CREDENTIALS.md` for the Ludus login password set at creation
time. Retrieve/reset the Proxmox credential with:
```bash
ludus users creds get -u DSTEAM1
ludus users apikey -u DSTEAM1
```

## Verify
1. Open an incognito browser → `https://<proxmox-host>:8006`.
2. Log in as `detection-range-team-1-splunk` (realm **pam**).
3. Confirm: only the `DS` pool/VMs are visible; Console opens; other ranges
   are absent; no shell/template/admin actions are available.
