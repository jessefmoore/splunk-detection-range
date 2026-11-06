#!/usr/bin/env bash
# =============================================================================
# install-roles.sh — install every Ansible role the DS range needs into Ludus.
# Run on a machine with the `ludus` CLI configured for the deploying user
# (Ludus v2 CLI — https://docs.ludus.cloud/docs/using-ludus/cli).
# Idempotent: re-running just re-adds/updates the roles.
#
# Usage:  ./install-roles.sh [--user TEAMID]
#   --user TEAMID   install into another user's scope (admin only, -u/--user)
#
# Confirmed against this Ludus server on 2026-11-06:
#   - p4t12ick.ludus_ar_splunk    (already present, v1.1.3)
#   - p4t12ick.ludus_ar_windows   (already present, v1.1.2)
#   - frack113.ludus_caldera_server / ludus_caldera_agent (reused from DE range)
#   - j91321.atomic_red_team                               (reused from DE range)
#   - art_psmodule_prereq (custom, user-scoped, reused from DE range — see
#     roles/ROLE_CONVENTIONS.md if it needs re-installing on a new server)
# =============================================================================
set -euo pipefail
USER_ARG=""
[[ "${1:-}" == "--user" ]] && USER_ARG="-u ${2:?user id required}"

echo "==> Installing roles from Ansible Galaxy"
ludus ansible role add p4t12ick.ludus_ar_splunk    $USER_ARG || true
ludus ansible role add p4t12ick.ludus_ar_windows   $USER_ARG || true
ludus ansible role add frack113.ludus_caldera_server $USER_ARG || true
ludus ansible role add frack113.ludus_caldera_agent  $USER_ARG || true
ludus ansible role add j91321.atomic_red_team        $USER_ARG || true

echo "==> Done. Verify with:  ludus ansible role list $USER_ARG"
echo "==> Note: art_psmodule_prereq is a custom local role (user-scoped on"
echo "    this server already). If deploying fresh elsewhere, install it with:"
echo "    ludus ansible role add -d roles/art_psmodule_prereq --force"
