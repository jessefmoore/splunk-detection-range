#!/usr/bin/env bash
# =============================================================================
# snapshot.sh — snapshot or restore the DS range (e.g. before/after a Caldera
# operation, so the AD/endpoint state can be reset for the next run).
# =============================================================================
set -euo pipefail
RANGEID="${2:-DS}"

case "${1:-}" in
  start)
    echo "==> Snapshotting $RANGEID and entering testing state"
    ludus testing start -r "$RANGEID"
    ;;
  stop)
    echo "==> Reverting $RANGEID to pre-testing snapshot"
    ludus testing stop -r "$RANGEID"
    ;;
  list)
    ludus range snapshots -r "$RANGEID"
    ;;
  *)
    echo "Usage: $0 {start|stop|list} [RANGEID]"
    exit 1
    ;;
esac
