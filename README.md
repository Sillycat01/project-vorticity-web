# Project Vorticity

A WRF-based mesoscale weather-model workstation workflow for Ubuntu/WSL2. The initial installer checks existing software before installing anything, then prepares dependencies and WRF/WPS source trees. Transparent setup: no silent overwrites and logs are retained.

**Status:** Early bootstrap. This is not yet a turnkey forecast pipeline; it does not download meteorological datasets, configure a domain, or claim a validated build.

## Target
- Ubuntu on WSL2 (recommended) or native Ubuntu (not yet fully tested)
- GNU toolchain, NetCDF, MPI, Python
- WRF + WPS compiled locally

## Quick start
```bash
git clone https://github.com/Sillycat01/project-vorticity-web.git
cd project-vorticity-web
chmod +x scripts/*.sh
./scripts/install.sh
```
The installer checks the system, reports existing installations, asks before package changes, and then prepares sources. Compilation is intentionally not automatic in this bootstrap.

## Commands
- `./scripts/check-system.sh` — read-only diagnostics
- `./scripts/status.sh` — software/source detection
- `./scripts/install.sh` — dependency and source setup

Configuration: copy `config/example.env` to `config/local.env`. The latter is ignored by Git.

Upstream: https://github.com/wrf-model/WRF and https://github.com/wrf-model/WPS. Follow their licenses and documentation. This independent project is not affiliated with NCAR or WRF.