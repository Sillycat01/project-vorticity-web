# Roadmap

## Phase 0 — repository bootstrap
- [x] README and configuration template
- [x] WSL/Ubuntu and dependency diagnostics
- [x] Scan for existing installations before actions
- [x] Prompt before installing packages
- [x] Clone source without deleting existing directories or resetting local changes

## Phase 1 — tested build profiles
- [ ] Pin validated upstream versions
- [ ] Detect compiler, NetCDF and MPI compatibility
- [ ] WRF serial/MPI build profiles and validation
- [ ] WPS build against matching libraries
- [ ] Log collection, error summaries and resume support

## Phase 2 — preprocessing/data
- [ ] Guided domain configuration
- [ ] Supported data provider integrations
- [ ] geogrid/ungrib/metgrid configuration and checks
- [ ] Input file verification and disk-space checks

## Phase 3 — model runs
- [ ] Namelist generator with validated presets
- [ ] Run management, monitoring, logs, cancel/restart
- [ ] Output detection and visualization

## Phase 4 — desktop/web UI
- [ ] Guided installation/system check
- [ ] Domain/data/forecast wizard
- [ ] Run controls and diagnostics
- [ ] Plot and map explorer
