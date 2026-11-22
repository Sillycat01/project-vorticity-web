# Project Vorticity

A WRF-based mesoscale weather-model workstation workflow for Ubuntu/WSL2.

## Download without using a command line

1. Open the [Project Vorticity repository](https://github.com/Sillycat01/project-vorticity-web).
2. Select **Code → Download ZIP**.
3. Extract the ZIP in Windows.
4. Double-click **Start-ProjectVorticity.bat**.
5. Select your installed Ubuntu/WSL distribution and use the graphical setup window.

The graphical launcher is an early preview. It requires Windows 10/11 with WSL2 and an already-installed Ubuntu distribution. It does not install or configure WSL itself. The launcher is not yet a signed Windows installer.

## Current capabilities

- Windows WinForms launcher for WSL selection and diagnostics
- Ubuntu/WSL dependency and existing-install detection
- Interactive setup script for build dependencies and WRF/WPS source checkouts
- Pinned source tags in the example configuration (WRF v4.8.0 and WPS v4.7.0)
- Initial WRF/WPS build driver with build logs and executable checks

## Important limitations

This repository is an early development build, not a finished forecasting application. The Windows launcher and setup process have not yet been validated on your computer. WRF and WPS compilation requires selecting matching compiler/MPI configuration options; the current build driver still invokes the upstream configuration menus. The source tags have not yet been verified as a tested compatible pair.

The current release does not yet include automated GRIB data acquisition, a domain wizard, fully automated WPS preprocessing, a WRF run manager, or a finished graphical forecast viewer. It does not bundle static geogrid data or forecast datasets.

## Development commands (optional)

For developers only:
- `scripts/check-system.sh` — system diagnostics
- `scripts/status.sh` — installation detection
- `scripts/install.sh` — dependency/source setup
- `scripts/build-wrf-wps.sh` — WRF/WPS build workflow

## Upstream projects

- [WRF](https://github.com/wrf-model/WRF)
- [WPS](https://github.com/wrf-model/WPS)

Follow upstream licenses, documentation, and data terms. Project Vorticity is independent and is not affiliated with NCAR.
