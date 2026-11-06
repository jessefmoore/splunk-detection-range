#!/usr/bin/env bash
# =============================================================================
# create-team-user.sh — create a non-admin user and give them console-only
# Proxmox access to the DS range (admin only).
#
# Usage:  ./create-team-user.sh TEAMID "Display Name" EMAIL RANGEID
#   e.g.  ./create-team-user.sh DSTEAM1 "Detection Range Team 1" dsteam1@grayhats.local DS
# =============================================================================
set -euo pipefail
TEAMID="${1:?team id (alphanumeric, e.g. DSTEAM1)}"
NAME="${2:?team display name}"
EMAIL="${3:?email (required by the Ludus user API)}"
RANGEID="${4:-DS}"

echo "==> Creating non-admin user $TEAMID"
ludus users add --name "$NAME" --userid "$TEAMID" --email "$EMAIL"   # NOT --admin => non-admin

echo "==> Assigning range $RANGEID to $TEAMID (grants scoped Proxmox console access)"
ludus range assign "$TEAMID" "$RANGEID"

cat <<EOF

==> Done.
    - The team logs into Proxmox at https://<proxmox-host>:8006 with the
      Ludus-generated proxmox credentials for user '$TEAMID' (realm: pam).
    - Get those credentials with:  ludus users creds get -u $TEAMID
    - They will see ONLY the '$RANGEID' pool and can open each VM's Console.
    - They are NOT admins: no template building, no other ranges, no shell.
EOF
