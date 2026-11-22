# Development roadmap

## Bootstrap and download
- [x] Repository scaffold and docs
- [x] Ubuntu/WSL diagnostics and existing-install scan
- [x] Dependency/source installer
- [x] Windows graphical launcher
- [x] Source ZIP download instructions
- [ ] Validate graphical install on clean Windows + WSL2

## Build pipeline
- [x] Initial WRF/WPS build driver and logs
- [ ] Validate WRF 4.8.0 + WPS 4.7.0 compatibility
- [ ] Automated compiler/MPI profile selection
- [ ] CI build and runtime smoke test
- [ ] Fully graphical build controls

## Preprocessing and data
- [ ] Domain wizard and namelist.wps editor
- [ ] Geogrid static-data manager
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
