# Development roadmap

## Bootstrap and download
- [x] Repository scaffold and docs
- [x] Ubuntu/WSL diagnostics and existing-install scan
- [x] WSL dependency installer
- [x] Windows graphical launcher with setup/build controls
- [x] Source ZIP download instructions
- [ ] Validate graphical install on clean Windows + WSL2

## Build pipeline
- [x] Automated GNU Fortran + OpenMPI profile selection from upstream menus
- [x] WRF `em_real` build workflow
- [x] WPS build workflow with bundled GRIB2 libraries
- [x] Build logs and executable checks
- [ ] Validate WRF 4.8.0 + WPS 4.7.0 compatibility on a clean system
- [ ] CI build and runtime smoke test

## Real-data forecast pipeline
- [x] Single-domain WPS namelist generation
- [x] geogrid → ungrib → metgrid orchestration
- [x] WRF namelist generation and real.exe / wrf.exe run driver
- [x] Timestamped forecast run directories and logs
- [x] Windows GUI controls to configure and launch a forecast
- [ ] Automated WPS static-geography dataset setup
- [ ] GRIB data-provider integration and automatic cycle download
- [ ] Validate vertical-level metadata and physics against supported data providers
- [ ] Successful end-to-end forecast test on a clean WSL2 machine
- [ ] Scientific output validation against observations/reference forecasts

## Forecast and visualization
- [ ] Domain wizard and multi-domain support
- [ ] namelist.input / namelist.wps graphical editors
- [ ] WRF run manager, progress, restart and cancellation
- [ ] Output inspection and plotting
- [ ] Meteorological map viewer

## Distribution
- [x] GitHub ZIP source download
- [ ] Signed Windows installer
- [ ] Automated releases and end-to-end tests
