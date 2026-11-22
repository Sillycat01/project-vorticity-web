#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
pv_load_config
pv_require git; pv_require gfortran; pv_require gcc; pv_require make
WPS_DIR="$PV_SRC/WPS"
WRF_DIR="$PV_SRC/WRF"
[[ -d "$WPS_DIR" ]] || pv_die "WPS source missing. Run installer first."
[[ -f "$WRF_DIR/WRF/main/wrf.exe" || -f "$WRF_DIR/main/wrf.exe" ]] || pv_log "WRF executable not found yet (WPS can be configured, but test workflow needs WRF)."
echo "WPS compile expects the same compiler/library stack used by WRF."
read -r -p "Run WPS configure? [y/N] " yn
[[ "$yn" =~ ^[Yy]$ ]] || exit 0
cd "$WPS_DIR"
./configure
[[ -f configure.wps ]] || pv_die "configure.wps not generated."
read -r -p "Compile WPS with ${PV_JOBS:-2} jobs? [y/N] " build
[[ "$build" =~ ^[Yy]$ ]] || exit 0
LOG="$(pv_log_file wps-build)"
pv_log "Building WPS; log: $LOG"
./compile 2>&1 | tee "$LOG"
for exe in geogrid.exe ungrib.exe metgrid.exe; do
 [[ -e "$WPS_DIR/$exe" ]] || pv_log "WARNING: $exe missing; build may be incomplete."
done
pv_log "WPS build attempt finished; inspect output and verify executables."
