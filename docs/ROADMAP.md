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

## Preprocessing and data
- [ ] Domain wizard and namelist.wps editor
- [ ] Geogrid static-data manager and automatic static-data download
- [ ] GRIB data provider integrations
- [ ] Vtable selection and ungrib/metgrid orchestration
- [ ] Input validation and preprocessing reports

## Forecast and visualization
- [ ] namelist.input wizard
- [ ] WRF run manager, progress, restart and cancellation
- [ ] Output inspection and plotting
- [ ] Meteorological map viewer

## Distribution
- [x] GitHub ZIP source download
- [ ] Signed Windows installer
- [ ] Automated releases and end-to-end tests
