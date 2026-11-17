#!/usr/bin/env bash
# =============================================================================
# deploy.sh — push the DS range config and deploy it, for CLI-based operation
# without `ludus blueprint apply` (see README.md Quick Start for the
# blueprint-based path, which most users should prefer).
#
# ludus_ar_windows_splunk_ip is templated with {{ range_second_octet }} in
# range-config.yml, so no manual IP edit is needed before deploying.
#
# Usage:  ./deploy.sh [RANGEID] [TEAMID]
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."
RANGEID="${1:-DS}"
TEAMID="${2:-}"
RANGE_ARG="-r $RANGEID"
USER_ARG=""; [[ -n "$TEAMID" ]] && USER_ARG="-u $TEAMID"
CONFIG="blueprints/splunk-detection-range/range-config.yml"

echo "==> Setting range config for $RANGEID"
ludus range config set -f "$CONFIG" $RANGE_ARG $USER_ARG

echo "==> Deploying range $RANGEID (expect 1-3 hours for all VMs + AD + roles)"
ludus range deploy $RANGE_ARG $USER_ARG

echo "==> Follow progress with:  ludus range logs -f $RANGE_ARG $USER_ARG"
echo "==> Status with:           ludus range list $RANGE_ARG $USER_ARG"
