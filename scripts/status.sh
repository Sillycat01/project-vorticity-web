#!/usr/bin/env bash
set -euo pipefail
PV_ROOT="${PV_ROOT:-$HOME/ProjectVorticity}"
PV_SRC="${PV_SRC:-$PV_ROOT/src}"
printf 'Project Vorticity status\nRoot: %s\n' "$PV_ROOT"

for software in WRF WPS; do
  dir="$PV_SRC/$software"
  if [[ -d "$dir" ]]; then
    printf '[FOUND] %s source at %s\n' "$software" "$dir"
  else
    printf '[MISSING] %s source at %s\n' "$software" "$dir"
  fi
done

for pair in "WRF:$PV_SRC/WRF/main/wrf.exe" "WRF-real:$PV_SRC/WRF/main/real.exe" "WPS-geogrid:$PV_SRC/WPS/geogrid.exe" "WPS-ungrib:$PV_SRC/WPS/ungrib.exe" "WPS-metgrid:$PV_SRC/WPS/metgrid.exe"; do
  label="${pair%%:*}"
  path="${pair#*:}"
  if [[ -x "$path" ]]; then printf '[READY] %s executable\n' "$label"; else printf '[PENDING] %s executable\n' "$label"; fi
done

for cmd in gcc gfortran mpicc mpif90 nc-config nf-config; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '[OK] %-10s %s\n' "$cmd" "$(command -v "$cmd")"
  else
    printf '[MISSING] %s\n' "$cmd"
  fi
done
command -v df >/dev/null && df -h "$HOME" || true
command -v free >/dev/null && free -h || true
