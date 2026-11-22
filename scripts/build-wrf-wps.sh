#!/usr/bin/env bash
set -euo pipefail
ROOT="\${PV_ROOT:-$HOME/ProjectVorticity}"
SRC="\${PV_SRC:-$ROOT/src}"
mkdir -p "$ROOT/logs"
LOG="$ROOT/logs/build-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1
for c in gcc gfortran make mpif90 nf-config nc-config; do command -v "$c" >/dev/null 2>&1 || { echo "Missing required command: $c"; exit 2; }; done
export NETCDF="$(nf-config --prefix)"
export WRF_DIR="$SRC/WRF"
export WPS_DIR="$SRC/WPS"
[[ -d "$WRF_DIR" && -d "$WPS_DIR" ]] || { echo "WRF/WPS sources missing. Run installer first."; exit 2; }
echo "NetCDF: $NETCDF"
cd "$WRF_DIR"
if [[ ! -x main/wrf.exe || ! -x main/real.exe ]]; then
 echo "WRF configure requires selecting the compiler/MPI option for this machine."
 ./configure
 ./compile -j "\${PV_JOBS:-2}" em_real
fi
[[ -x main/wrf.exe && -x main/real.exe ]] || { echo "WRF executables missing after compile."; exit 3; }
cd "$WPS_DIR"
if [[ ! -x geogrid.exe || ! -x ungrib.exe || ! -x metgrid.exe ]]; then
 echo "Select the WPS configure option matching the WRF compiler/MPI profile."
 ./configure
 ./compile
fi
for exe in geogrid.exe ungrib.exe metgrid.exe; do [[ -x "$exe" ]] || { echo "Missing $exe"; exit 4; }; done
echo "WRF/WPS executable validation passed."
