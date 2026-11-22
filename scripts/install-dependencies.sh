#!/usr/bin/env bash
# Run as root from the Windows launcher (WSL) to install the build toolchain.
set -Eeuo pipefail
if [[ "$(id -u)" -ne 0 ]]; then
  echo "This dependency stage must run as root. The Windows launcher starts it through WSL's root account."
  exit 2
fi
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  build-essential gcc g++ gfortran make cmake git curl wget ca-certificates \
  m4 perl flex bison autoconf automake libtool pkg-config tcsh \
  openmpi-bin libopenmpi-dev \
  libnetcdf-dev libnetcdff-dev netcdf-bin libhdf5-dev \
  libpng-dev zlib1g-dev \
  python3 python3-pip python3-venv python3-dev
echo
echo "Dependency installation complete."
echo "NetCDF prefix: $(nf-config --prefix)"
echo "MPI Fortran wrapper: $(command -v mpif90)"
