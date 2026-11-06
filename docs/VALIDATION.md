# DS — Post-Deploy Validation Checklist

Run through this after `scripts/deploy.sh` (or the MCP `deployRange` call)
reports success.

## 1. AD / DNS (DS-dc01, DS-win01)
- [ ] `DS-dc01` is reachable; `nslookup grayhats.local` from `DS-win01`
      resolves against the DC.
- [ ] `DS-win01` shows up in **Active Directory Users and Computers** under
      `grayhats.local` as a domain-joined computer.
- [ ] Log into `DS-win01` as `GRAYHATS\grayhatsuser` with the password from
      `docs/CREDENTIALS.md`.
- [ ] **If DS-dc01 never came up** (console shows a forced Administrator
      password prompt, Ansible reports it `unreachable`): this is the known
      `win2025-server-x64-tpm-template` risk documented in `docs/VMS.md`.
      Do not assume it's unfixable by retrying — but also don't loop
      indefinitely; report back for a decision on next steps.

## 2. Splunk (DS-splunk01)
- [ ] Splunk web UI reachable at `https://<DS-splunk01-ip>:8000`, login
      `admin` / the `ludus_ar_splunk_password` value from
      `docs/CREDENTIALS.md`.
- [ ] **Settings → Forwarder Management** (or `Universal Forwarders` app)
      shows `DS-dc01` and `DS-win01` phoning home.
- [ ] Run a search (`index=* host=DS-dc01`, last 24h) and confirm events are
      arriving (Windows Event Log, Sysmon, etc.).

## 3. Caldera (DS-caldera01)
- [ ] Caldera UI reachable at `http://<DS-caldera01-ip>:8888`.
- [ ] Log in as `red` / `ludus_caldera_red_pwd` (see `docs/CREDENTIALS.md`).
- [ ] **Agents** view shows Sandcat agents checked in from `DS-dc01` and
      `DS-win01`.
- [ ] Run a single, low-impact ability against one agent and confirm it
      completes.

## 4. Atomic Red Team (DS-artwin01)
- [ ] RDP/console into `DS-artwin01`.
- [ ] In an elevated PowerShell session:
      ```powershell
      Import-Module "C:\AtomicRedTeam\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1" -Force
      Invoke-AtomicTest T1082 -ShowDetailsBrief
      ```

## 5. Purple-team loop (end to end)
- [ ] Pick one simple Caldera ability that maps to an Atomic Red Team test.
- [ ] Validate it on `DS-artwin01` first with `Invoke-AtomicTest`.
- [ ] Run the equivalent Caldera ability against `DS-win01` from
      `DS-caldera01`.
- [ ] Confirm the resulting telemetry appears in a Splunk search on
      `DS-splunk01`.

## 6. Access control (DSTEAM1)
- [ ] Log into Proxmox as `detection-range-team-1-splunk` and confirm only
      the `DS` pool is visible, console-only (see `docs/ACCESS-CONTROL.md`).
