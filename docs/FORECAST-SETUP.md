# Running a real-data WRF forecast

Project Vorticity's forecast runner is a **single-domain ARW real-data workflow**. It runs geogrid, ungrib, metgrid, real.exe and wrf.exe in sequence. It does not generate weather observations or boundary conditions itself: those must come from a forecast-data provider.

## Before the first run

1. Build WRF and WPS using the Windows launcher.
2. Obtain and extract the WPS static geography dataset. It must contain the geogrid static fields expected by the WPS release. Keep it outside the source checkout; the dataset is large and is not bundled with Project Vorticity.
3. Obtain GRIB forecast files for one consistent model cycle/provider. The files must cover the configured start and end times and contain the fields required by the selected WPS Vtable. Include all intermediate boundary-condition times.
4. Confirm the GRIB interval (for example, three-hourly) and choose the matching Vtable. The starter template uses `GFS`; use it only for compatible GFS GRIB products.

## Configure in the Windows app

Choose **3. Configure forecast**. The app creates and opens:

`~/ProjectVorticity/config/forecast.env`

Edit the values and save the file:

- `PV_START`, `PV_END`: UTC times in `YYYY-MM-DD_HH:MM:SS` format
- `PV_CENTER_LAT`, `PV_CENTER_LON`: forecast-domain centre in decimal degrees
- `PV_GEOG_DIR`: extracted static geography directory
- `PV_GRIB_DIR`: directory containing the GRIB files for the chosen forecast cycle
- `PV_VTABLE`: matching WPS Vtable name, without the `Vtable.` prefix
- `PV_INTERVAL_SECONDS`: interval between GRIB analyses/forecast fields
- `PV_NUM_METGRID_LEVELS`, `PV_NUM_METGRID_SOIL_LEVELS`, `PV_NUM_SOIL_LAYERS`: vertical/soil level counts that must match the selected data and WPS output
- Grid dimensions, spacing, projection and MPI rank count

The example uses one 100 x 100 grid at 12-km spacing. It is only a starter configuration. Select a domain, grid spacing, projection parameters and physics suitable for the region, terrain, data source and forecast objective. The example physics suite is not a universal best choice.

## Run

Click **4. Run forecast**. The runner creates a timestamped run folder under `~/ProjectVorticity/runs` and a log under `~/ProjectVorticity/logs`. It performs:

1. WPS geogrid static-field interpolation
2. GRIB linking and ungrib decoding
3. WPS metgrid horizontal interpolation
4. WRF real.exe initial/boundary condition generation
5. WRF wrf.exe integration

The expected final products are `wrfout_d01_*` NetCDF files in the run's `WRF` folder.

## Important caveats

- The current runner supports one domain and the ARW core only.
- It does not download GRIB forecasts or static geography automatically.
- The GRIB provider, Vtable, forecast interval, projection, domain and physics must be mutually compatible.
- The starter WRF namelist defaults to 34 metgrid atmospheric levels and 4 soil levels. Set the corresponding level-count values in `forecast.env` to match the selected input dataset and generated WPS fields.
- A successful process exit is not scientific validation. Check WRF logs for CFL errors, missing fields, boundary problems and model instability; compare output against observations and a trusted forecast.
- Do not use this preview for emergency decisions or operational safety forecasting.
