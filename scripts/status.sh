#!/usr/bin/env bash
set -euo pipefail
PV_ROOT="${PV_ROOT:-$HOME/ProjectVorticity}"PV_SRC="${PV_SRC:-$PV_ROOT/src}"printf 'Project Vorticity status\nRoot: %s\n' "$PV_ROOT"
for software in WRF WPS; do
 dir="$PV_SRC/$software" if [[ -d "$dir" ]]; then printf '[FOUND] %s source at %s\n' "$software" "$dir"; else printf '[MISSING] %s source at %s\n' "$software" "$dir"; fi
done
for cmd in gcc gfortran mpif90 nc-config nf-config; do
 if command -v "$cmd" >/dev/null 2>&1; then printf '[OK] %-10s %s\n' "$cmd" "$(command -v "$cmd")"; else printf '[--] %-10s missing\n' "$cmd"; fi
done
