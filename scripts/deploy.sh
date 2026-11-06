#!/usr/bin/env bash
# =============================================================================
# deploy.sh — push the DS range config and deploy it.
#
# IMPORTANT: ds-range.yml's global_role_vars.ludus_ar_windows_splunk_ip must
# be filled in with DS-splunk01's real IP (10.<range_number>.40.35) BEFORE
# running this — p4t12ick.ludus_ar_windows has no auto-discovery. Create the
# range first (`ludus range create` / createRange) to learn the range number.
#
# Usage:  ./deploy.sh [RANGEID] [TEAMID]
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."
RANGEID="${1:-DS}"
TEAMID="${2:-}"
RANGE_ARG="-r $RANGEID"
USER_ARG=""; [[ -n "$TEAMID" ]] && USER_ARG="-u $TEAMID"

if grep -q "REPLACE_AFTER_CREATE_RANGE" ds-range.yml; then
  echo "!! ds-range.yml still has the ludus_ar_windows_splunk_ip placeholder."
  echo "!! Fill in the real DS-splunk01 IP before deploying. Aborting."
  exit 1
fi

echo "==> Setting range config for $RANGEID"
ludus range config set -f ds-range.yml $RANGE_ARG $USER_ARG

echo "==> Deploying range $RANGEID (expect 1-3 hours for all VMs + AD + roles)"
ludus range deploy $RANGE_ARG $USER_ARG

echo "==> Follow progress with:  ludus range logs -f $RANGE_ARG $USER_ARG"
echo "==> Status with:           ludus range list $RANGE_ARG $USER_ARG"
