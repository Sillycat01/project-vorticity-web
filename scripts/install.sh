#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT_DIR/config/local.env"
[[ -f "$CONFIG" ]] || CONFIG="$ROOT_DIR/config/example.env"
# shellcheck disable=SC1090
source "$CONFIG"
mkdir -p "$PV_SRC" "$PV_BUILD" "$PV_LOG"
LOG_FILE="$PV_LOG/install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== Project Vorticity installer ==="
echo "Configuration: $CONFIG"
echo "Log: $LOG_FILE"
"$ROOT_DIR/scripts/check-system.sh"
echo "Existing software/source scan:"
for path in "$PV_SRC/WRF" "$PV_SRC/WPS" "$HOME/WRF" "$HOME/WPS" /usr/local/WRF /usr/local/WPS; do
  [[ -d "$path" ]] && echo "[EXISTS] $path"
done
for cmd in gcc gfortran git make nc-config nf-config mpif90; do
  command -v "$cmd" >/dev/null 2>&1 && echo "[EXISTS] $cmd -> $(command -v "$cmd")" || echo "[MISSING] $cmd"
done
echo "Plan: install missing Ubuntu build packages, then clone WRF and WPS sources."
echo "Existing directories are never deleted, and git checkouts are not reset."
if [[ "${PV_ASSUME_YES:-0}" == "1" ]]; then confirm="y"; else read -r -p "Proceed? [y/N] " confirm; fi
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }
if [[ "${PV_INSTALL_DEPS:-true}" == "true" ]]; then
  command -v apt-get >/dev/null || { echo "apt-get unavailable; install dependencies manually."; exit 2; }
  sudo apt-get update
  sudo apt-get install -y build-essential gcc g++ gfortran make cmake git curl wget m4 perl flex bison libtool pkg-config openmpi-bin libopenmpi-dev libnetcdf-dev libnetcdff-dev netcdf-bin libhdf5-dev python3 python3-pip python3-venv python3-dev
fi
clone_source() {
  local repo="$1" target="$2" ref="$3"
  if [[ -d "$target/.git" ]]; then
    echo "Git checkout exists at $target; fetch only (no reset or destructive checkout)."
    git -C "$target" fetch --tags --all
  elif [[ -e "$target" ]]; then
    echo "ERROR: $target exists but is not a Git checkout. Leaving it untouched." >&2
    return 3
  else
    git clone --depth 1 --branch "$ref" "$repo" "$target"
  fi
  if [[ -n "$ref" ]]; then git -C "$target" checkout "$ref"; fi
}
clone_source "$PV_WRF_REPO" "$PV_SRC/WRF" "$PV_WRF_REF"
clone_source "$PV_WPS_REPO" "$PV_SRC/WPS" "$PV_WPS_REF"
echo "Dependency and source stage complete. Use scripts/build-wrf-wps.sh for the compiler configuration and build stage."
echo "Check status with: $ROOT_DIR/scripts/status.sh"
