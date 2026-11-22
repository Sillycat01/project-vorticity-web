#!/usr/bin/env bash
set -euo pipefail
info(){ printf '[INFO] %s\n' "$*"; }
warn(){ printf '[WARN] %s\n' "$*"; }
fail(){ printf '[ERROR] %s\n' "$*" >&2; exit 1; }
[[ -f /etc/os-release ]] || fail 'Cannot identify OS.'
. /etc/os-release
info "OS: ${PRETTY_NAME:-unknown}"
[[ "${ID:-}" == ubuntu ]] || warn 'Ubuntu is recommended; other distributions are not tested.'
if grep -qi microsoft /proc/version 2>/dev/null; then info 'WSL detected'; else warn 'WSL not detected; native Linux support is not yet validated.'; fi
for cmd in bash git curl wget gcc gfortran make python3; do
 if command -v "$cmd" >/dev/null 2>&1; then info "Found $cmd: $(command -v "$cmd")"; else warn "Missing $cmd"; fi
done
command -v df >/dev/null && df -h "$HOME" || true
command -v free >/dev/null && free -h || true
command -v nproc >/dev/null && info "CPU threads: $(nproc)" || true
command -v nc-config >/dev/null && info "NetCDF C: $(nc-config --version 2>/dev/null || true)" || warn 'NetCDF C development tools missing'
command -v nf-config >/dev/null && info "NetCDF Fortran: $(nf-config --version 2>/dev/null || true)" || warn 'NetCDF Fortran development tools missing'
