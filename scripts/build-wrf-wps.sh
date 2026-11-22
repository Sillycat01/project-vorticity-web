#!/usr/bin/env bash
# Automated GNU + OpenMPI build for WRF/WPS on Ubuntu/WSL2.
set -Eeuo pipefail

ROOT="${PV_ROOT:-$HOME/ProjectVorticity}"
SRC="${PV_SRC:-$ROOT/src}"
JOBS="${PV_JOBS:-2}"
WRF_DIR="$SRC/WRF"
WPS_DIR="$SRC/WPS"
mkdir -p "$ROOT/logs"
LOG="$ROOT/logs/build-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

fail() { echo "ERROR: $*" >&2; exit 2; }
echo "=== Project Vorticity: WRF/WPS build ==="
echo "Log: $LOG"
[[ "$JOBS" =~ ^[1-9][0-9]*$ ]] || fail "PV_JOBS must be a positive integer."
for c in gcc gfortran make mpif90 nf-config nc-config awk sed timeout; do
  command -v "$c" >/dev/null 2>&1 || fail "Missing required command: $c. Run the dependency installer first."
done
[[ -d "$WRF_DIR" && -d "$WPS_DIR" ]] || fail "WRF or WPS source checkout is missing. Run Install first."
export NETCDF="$(nf-config --prefix)"
export WRF_DIR WPS_DIR
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
export OMP_NUM_THREADS=1
export MAKEFLAGS="-j$JOBS"
echo "GNU Fortran: $(gfortran --version | head -n 1)"
echo "MPI: $(mpif90 --version | head -n 1)"
echo "NetCDF: $NETCDF"
echo "Build parallelism: $JOBS"

# Ask upstream's configure script to print its menu, then select the GNU
# gfortran/gcc distributed-memory (dmpar) profile by matching its label.
# This avoids hard-coding menu numbers that can change between WRF releases.
choose_gnu_dmpar() {
  local dir="$1" menu="$2" label="$3" choice
  local tmp
  tmp="$(mktemp)"
  (cd "$dir" && timeout 8 ./configure </dev/null) >"$tmp" 2>&1 || true
  choice="$(awk '
    {
      line=tolower($0)
      if (line ~ /^[[:space:]]*[0-9]+[.)][[:space:]]/ &&
          line ~ /gfortran/ && line ~ /dmpar/) {
        match($0, /^[[:space:]]*[0-9]+/)
        print substr($0, RSTART, RLENGTH)
        exit
      }
    }' "$tmp")"
  if [[ -z "$choice" ]]; then
    echo "Could not identify a GNU + OpenMPI dmpar option in $label configure menu."
    echo "The menu captured from upstream is shown below for diagnosis:"
    cat "$tmp"
    rm -f "$tmp"
    fail "No safe automatic compiler profile was found. No guessed menu choice was made."
  fi
  echo "$choice"
  rm -f "$tmp"
}

build_wrf() {
  cd "$WRF_DIR"
  if [[ -x main/wrf.exe && -x main/real.exe ]]; then
    echo "[SKIP] WRF executables already exist."
    return
  fi
  echo "[WRF] Detecting upstream GNU/OpenMPI configuration option..."
  local choice
  choice="$(choose_gnu_dmpar "$WRF_DIR" "" "WRF")"
  echo "[WRF] Selecting configure option $choice (GNU + gfortran/gcc + dmpar)."
  # WRF's configure asks for a nesting mode after the compiler selection.
  printf '%s\n1\n' "$choice" | ./configure
  echo "[WRF] Compiling em_real with $JOBS job(s)..."
  ./compile -j "$JOBS" em_real
  [[ -x main/wrf.exe && -x main/real.exe ]] || fail "WRF compile finished without both main/wrf.exe and main/real.exe."
}

build_wps() {
  cd "$WPS_DIR"
  if [[ -x geogrid.exe && -x ungrib.exe && -x metgrid.exe ]]; then
    echo "[SKIP] WPS executables already exist."
    return
  fi
  echo "[WPS] Detecting upstream GNU/OpenMPI configuration option..."
  local choice
  choice="$(choose_gnu_dmpar "$WPS_DIR" "" "WPS")"
  echo "[WPS] Selecting configure option $choice (must match WRF GNU/OpenMPI dmpar)."
  printf '%s\n' "$choice" | ./configure
  echo "[WPS] Compiling..."
  ./compile
  for exe in geogrid.exe ungrib.exe metgrid.exe; do
    [[ -x "$exe" ]] || fail "WPS compile finished without $exe."
  done
}

build_wrf
build_wps
echo
echo "SUCCESS: WRF and WPS executables passed validation."
echo "WRF: $WRF_DIR/main/wrf.exe"
echo "WRF real: $WRF_DIR/main/real.exe"
echo "WPS: $WPS_DIR/{geogrid,ungrib,metgrid}.exe"
echo "Build log: $LOG"
