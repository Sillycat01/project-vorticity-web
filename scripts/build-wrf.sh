#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
pv_load_config
pv_require git; pv_require gfortran; pv_require gcc; pv_require make
WRF_DIR="$PV_SRC/WRF"
[[ -d "$WRF_DIR" ]] || pv_die "WRF source not found. Run installer first."
[[ -f "$WRF_DIR/configure" ]] || pv_die "WRF configure script missing."
echo "WRF build: configure first, then select the compiler/MPI option interactively."
echo "If configure.wrf already exists, it will be preserved."
read -r -p "Run WRF configure now? [y/N] " yn
[[ "$yn" =~ ^[Yy]$ ]] || exit 0
cd "$WRF_DIR"
./configure
[[ -f configure.wrf ]] || pv_die "configure.wrf was not produced; configure may have failed."
read -r -p "Compile WRF em_real with ${PV_JOBS:-2} parallel jobs? [y/N] " build
[[ "$build" =~ ^[Yy]$ ]] || exit 0
LOG="$(pv_log_file wrf-build)"
pv_log "Compiling WRF. Log: $LOG"
./compile -j "${PV_JOBS:-2}" em_real 2>&1 | tee "$LOG"
[[ -f main/wrf.exe ]] || pv_die "wrf.exe missing after build. See $LOG"
pv_log "WRF real.exe/wrf.exe build target finished; verify both executables in main/."
