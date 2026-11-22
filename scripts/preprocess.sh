#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
pv_load_config
WPS_DIR="$PV_SRC/WPS"
RUN_DIR="${PV_RUN_DIR:-$PV_ROOT/runs/default}"
[[ -d "$WPS_DIR" ]] || pv_die "WPS source directory not found."
mkdir -p "$RUN_DIR"
for exe in geogrid.exe ungrib.exe metgrid.exe; do
 [[ -x "$WPS_DIR/$exe" ]] || pv_die "Missing executable: $WPS_DIR/$exe"
done
for file in namelist.wps Vtable GRIBFILE.AAA; do
 [[ -e "$RUN_DIR/$file" ]] || pv_log "Input not found yet: $RUN_DIR/$file"
done
pv_die "Preprocessing is not launched automatically yet. Configure the WPS domain, meteorological input files, and Vtable first. This script is a validation stub; it will not run incomplete preprocessing."
