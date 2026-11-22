#!/usr/bin/env bash
set -euo pipefail
pv_log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
pv_die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }
pv_require() { command -v "$1" >/dev/null 2>&1 || pv_die "Required command missing: $1"; }
pv_load_config() {
  local root
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  local config="$root/config/local.env"
  [[ -f "$config" ]] || config="$root/config/example.env"
  # shellcheck disable=SC1090
  source "$config"
  export PV_ROOT PV_SRC PV_BUILD PV_LOG PV_WRF_REPO PV_WPS_REPO PV_WRF_REF PV_WPS_REF PV_JOBS
  mkdir -p "$PV_BUILD" "$PV_LOG"
}
pv_log_file() {
  local tag="$1"
  local file="$PV_LOG/${tag}-$(date +%Y%m%d-%H%M%S).log"
  echo "$file"
}
