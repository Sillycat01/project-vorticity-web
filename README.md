# Project Vorticity

A WRF-based mesoscale weather-model workstation workflow for Ubuntu/WSL2.

## Download without using a command line

1. Open the [Project Vorticity repository](https://github.com/Sillycat01/project-vorticity-web).
2. Select **Code → Download ZIP**.
3. Extract the ZIP in Windows.
4. Double-click **Start-ProjectVorticity.bat**.
5. Select your installed Ubuntu/WSL distribution.
6. Click **1. Install dependencies + sources**. The launcher installs Linux packages as WSL root, then checks for existing WRF/WPS checkouts and downloads missing sources as your normal Linux user.
7. Click **2. Build WRF + WPS**. The build runs in the background and streams its log into the window.
8. Click **3. Configure forecast** to edit the UTC period, domain, static geography path and GRIB input folder.
9. Click **4. Run forecast** to execute WPS preprocessing and then WRF.

The graphical launcher is an early preview. It requires Windows 10/11 with WSL2 and an already-installed Ubuntu distribution. It does not install or configure WSL itself. The launcher is not yet a signed Windows installer.

## WRF/WPS build workflow

- Installs the GNU Fortran/C compiler toolchain, OpenMPI, NetCDF-C/Fortran, HDF5, and WPS compression prerequisites.
- Detects existing source checkouts and executables before downloading or compiling; it does not delete existing source trees.
- Reads the WRF and WPS configure menus and selects a GNU Fortran + distributed-memory (MPI) profile by matching the displayed option, rather than assuming a fixed menu number.
- Builds WRF in `em_real` mode, then configures WPS against that WRF tree.
- Uses WPS's built-in GRIB2 dependency build option for zlib, libpng, and JasPer. This is supported by WPS 4.4 and newer; see the [official WRF compilation guide](https://www2.mmm.ucar.edu/wrf/site/documentation/users_guide/compiling.html).
- Checks that `wrf.exe`, `real.exe`, `geogrid.exe`, `ungrib.exe`, and `metgrid.exe` exist before reporting success.
- Writes timestamped logs under `~/ProjectVorticity/logs`.

## Current capabilities

- Windows WinForms launcher for WSL selection and diagnostics
- GUI-driven dependency installation and source setup
- WRF/WPS GNU + OpenMPI build profile selection
- WRF `em_real` compilation and WPS compilation with bundled GRIB2 libraries
- Build logs and executable validation
- Single-domain real-data forecast runner: geogrid → ungrib → metgrid → real.exe → wrf.exe
- Generated WPS and WRF namelists from an editable forecast configuration
- Timestamped run folders and forecast logs
- Pinned source tags in the example configuration (WRF v4.8.0 and WPS v4.7.0)

## Important limitations

This is still an early development build, not a finished forecasting application. The automated build has been committed but has **not yet been run end-to-end on a clean Windows/WSL machine**. The WRF v4.8.0 + WPS v4.7.0 pair also still needs a clean-build compatibility test. Compilation can take a substantial amount of time and requires adequate free disk space and memory; the GUI currently uses two build jobs as a conservative default.

The forecast runner is an initial single-domain workflow, not a finished forecasting application. It currently requires the user to supply compatible GRIB forecast files and the WPS static-geography dataset; neither is downloaded automatically. The example configuration assumes a particular GRIB vertical-level layout and a starter physics suite, which must be checked against the selected input data. There is not yet a domain wizard, automated data-provider integration, multi-domain support, a forecast-output viewer, or scientific validation against observations. A successful run is not a guarantee of forecast accuracy.

## Developer scripts (optional)

- `scripts/check-system.sh` — system diagnostics
- `scripts/status.sh` — installation detection
- `scripts/install-dependencies.sh` — root-only Ubuntu package installation
- `scripts/install.sh` — source checkout and installation detection
- `scripts/build-wrf-wps.sh` — automated WRF/WPS build
- `scripts/run-forecast.sh` — single-domain WPS preprocessing and WRF integration
- `docs/FORECAST-SETUP.md` — input-data and forecast setup guide

## Upstream projects

- [WRF](https://github.com/wrf-model/WRF)
- [WPS](https://github.com/wrf-model/WPS)

Follow upstream licenses, documentation, and data terms. Project Vorticity is independent and is not affiliated with NCAR.
