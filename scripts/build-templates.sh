#!/usr/bin/env bash
# =============================================================================
# build-templates.sh — template strategy for the DS range.
#
# All required templates were already built on this Ludus server as of
# 2026-11-06 (debian-13 was built fresh during the sibling DE range build):
#
#   win2025-server-x64-tpm-template      -> DS-dc01     (AD 2025 + DNS; risk
#                                            flagged, see docs/VMS.md)
#   win11-22h2-x64-enterprise-template   -> DS-win01, DS-artwin01
#   ubuntu-24.04-x64-server-template     -> DS-caldera01, DS-splunk01
#   debian-13-x64-server-template        -> router
#
# This script exists for disaster recovery only — run it if one of the above
# templates is ever deleted from the server and needs to be rebuilt from ISO.
# Builds are slow (tens of minutes to a few hours per template).
#
# Usage:  ./build-templates.sh [template-name ...]
#   with no args, rebuilds all templates this range depends on.
# =============================================================================
set -euo pipefail

TEMPLATES=(
  "win2025-server-x64-tpm-template"
  "win11-22h2-x64-enterprise-template"
  "ubuntu-24.04-x64-server-template"
  "debian-13-x64-server-template"
)

TARGETS=("${@:-${TEMPLATES[@]}}")

echo "==> Rebuilding templates: ${TARGETS[*]}"
for t in "${TARGETS[@]}"; do
  echo "    - $t"
  ludus templates build --name "$t"
done

echo "==> Track progress with:  ludus templates status"
echo "==> Tail logs with:       ludus templates logs -f"
