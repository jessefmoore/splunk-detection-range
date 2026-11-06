# DS — Network

**Range ID:** `DS`  **Range number:** `31`  **IP scheme:** `10.31.<VLAN>.<octet>`

The 2nd octet is auto-assigned by Ludus on `POST /ranges/create` — not chosen
by us, mirroring the DE range's convention.

## VLANs

| VLAN | Purpose | Hosts |
|---|---|---|
| 10 | AD + endpoints (attacked by Caldera, defended by Splunk) | DS-dc01 (.31), DS-win01 (.32), DS-caldera01 (.33) |
| 30 | Atomic Red Team test bed | DS-artwin01 (.34) |
| 40 | Detection / SIEM | DS-splunk01 (.35) |

Router: Ludus auto-creates `DS-router-debian13-x64` once any VM references a
VLAN — nothing to configure manually. Pinned directly to
`debian-13-x64-server-template` (proven during the DE range build).

## Routing policy

```yaml
network:
  inter_vlan_default: ACCEPT
  external_default: ACCEPT
  wireguard_vlan_default: ACCEPT
```

Flat/ACCEPT during build, matching the reachability the design calls for —
Caldera01 ↔ DC01/WIN01, ARTWin01 → VLAN10, Splunk01 ↔ DC01/WIN01 (Universal
Forwarder data). `external_default: ACCEPT` is required for Caldera/Splunk
installer downloads, the Atomic Red Team GitHub clone, and Windows Update.

## Hardening for competition/exercise mode

Once the environment is built and roles have converged, tighten this to a
default-deny policy with explicit allow rules — see the DE range's
`docs/NETWORK.md` for a worked example (Elastic ports swapped for Splunk's
management port 8089 and the forwarder-to-indexer port 9997).
