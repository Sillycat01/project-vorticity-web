#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
pv_load_config
RUN_DIR="${PV_RUN_DIR:-$PV_ROOT/runs/default}"
WRF_DIR="$PV_SRC/WRF"
[[ -d "$RUN_DIR" ]] || pv_die "Run directory missing: $RUN_DIR"
[[ -x "$WRF_DIR/main/real.exe" ]] || pv_die "real.exe missing."
[[ -x "$WRF_DIR/main/wrf.exe" ]] || pv_die "wrf.exe missing."
for f in namelist.input met_em.d01*; do
  [[ -e "$RUN_DIR/$f" ]] || pv_log "Required run input not found: $RUN_DIR/$f"
done
pv_die "Run launch remains guarded until input validation and MPI profile are implemented. This prevents launching a run with incomplete inputs."
