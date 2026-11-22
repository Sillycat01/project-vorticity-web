#!/usr/bin/env bash
# End-to-end single-domain real-data WRF forecast driver.
set -Eeuo pipefail

ROOT="${PV_ROOT:-$HOME/ProjectVorticity}"
SRC="${PV_SRC:-$ROOT/src}"
WRF_DIR="$SRC/WRF"
WPS_DIR="$SRC/WPS"
RUNS_DIR="${PV_RUNS_DIR:-$ROOT/runs}"
CONFIG="${PV_FORECAST_CONFIG:-$ROOT/config/forecast.env}"
[[ -f "$CONFIG" ]] || { echo "Missing forecast config: $CONFIG" >&2; echo "Copy config/example-forecast.env to config/forecast.env and edit it." >&2; exit 2; }
# shellcheck disable=SC1090
source "$CONFIG"

fail() { echo "ERROR: $*" >&2; exit 2; }
need() { command -v "$1" >/dev/null 2>&1 || fail "Missing command: $1"; }
for c in date python3 mpirun; do need "$c"; done
for f in "$WRF_DIR/main/real.exe" "$WRF_DIR/main/wrf.exe" "$WPS_DIR/geogrid.exe" "$WPS_DIR/ungrib.exe" "$WPS_DIR/metgrid.exe"; do
  [[ -x "$f" ]] || fail "Required executable not found: $f. Build WRF/WPS first."
done

: "${PV_START:?Set PV_START in forecast.env (YYYY-MM-DD_HH:MM:SS)}"
: "${PV_END:?Set PV_END in forecast.env (YYYY-MM-DD_HH:MM:SS)}"
: "${PV_CENTER_LAT:?Set PV_CENTER_LAT in forecast.env}"
: "${PV_CENTER_LON:?Set PV_CENTER_LON in forecast.env}"
: "${PV_GEOG_DIR:?Set PV_GEOG_DIR to the extracted WPS static-geography directory}"
: "${PV_GRIB_DIR:?Set PV_GRIB_DIR to a folder containing GRIB forecast input files}"
: "${PV_VTABLE:?Set PV_VTABLE, e.g. GFS}"
PV_E_WE="${PV_E_WE:-100}"
PV_E_SN="${PV_E_SN:-100}"
PV_DX="${PV_DX:-12000}"
PV_DY="${PV_DY:-12000}"
PV_TRUELAT1="${PV_TRUELAT1:-25.0}"
PV_TRUELAT2="${PV_TRUELAT2:-25.0}"
PV_STAND_LON="${PV_STAND_LON:-$PV_CENTER_LON}"
PV_INTERVAL_SECONDS="${PV_INTERVAL_SECONDS:-10800}"
PV_MPI_RANKS="${PV_MPI_RANKS:-2}"
PV_HISTORY_MINUTES="${PV_HISTORY_MINUTES:-60}"
PV_TIME_STEP="${PV_TIME_STEP:-$((PV_DX / 1000 * 6))}"
PV_GEOG_RES="${PV_GEOG_RES:-default}"
PV_NUM_METGRID_LEVELS="${PV_NUM_METGRID_LEVELS:-34}"
PV_NUM_METGRID_SOIL_LEVELS="${PV_NUM_METGRID_SOIL_LEVELS:-4}"
PV_NUM_SOIL_LAYERS="${PV_NUM_SOIL_LAYERS:-4}"

[[ -d "$PV_GEOG_DIR" ]] || fail "Static geography directory does not exist: $PV_GEOG_DIR"
[[ -d "$PV_GRIB_DIR" ]] || fail "GRIB directory does not exist: $PV_GRIB_DIR"
[[ "$PV_GEOG_DIR" != *"'"* && "$PV_GRIB_DIR" != *"'"* ]] || fail "Data paths cannot contain single-quote characters."
[[ "$PV_E_WE" =~ ^[0-9]+$ && "$PV_E_SN" =~ ^[0-9]+$ && "$PV_DX" =~ ^[0-9]+$ && "$PV_DY" =~ ^[0-9]+$ ]] || fail "Grid dimensions and spacing must be positive integers."
[[ "$PV_MPI_RANKS" =~ ^[1-9][0-9]*$ ]] || fail "PV_MPI_RANKS must be a positive integer."
[[ "$PV_INTERVAL_SECONDS" =~ ^[1-9][0-9]*$ ]] || fail "PV_INTERVAL_SECONDS must be a positive integer."
[[ "$PV_NUM_METGRID_LEVELS" =~ ^[1-9][0-9]*$ && "$PV_NUM_METGRID_SOIL_LEVELS" =~ ^[1-9][0-9]*$ && "$PV_NUM_SOIL_LAYERS" =~ ^[1-9][0-9]*$ ]] || fail "Metgrid and soil level counts must be positive integers."
python3 - "$PV_CENTER_LAT" "$PV_CENTER_LON" "$PV_TRUELAT1" "$PV_TRUELAT2" "$PV_STAND_LON" <<'PY'
import sys
values = [float(x) for x in sys.argv[1:]]
lat, lon, t1, t2, stand = values
if not (-90 <= lat <= 90 and -180 <= lon <= 180):
    raise SystemExit("Forecast centre latitude/longitude are out of range.")
if not (-90 <= t1 <= 90 and -90 <= t2 <= 90 and -180 <= stand <= 180):
    raise SystemExit("Projection true latitudes/standard longitude are out of range.")
PY
[[ -f "$WPS_DIR/ungrib/Variable_Tables/Vtable.$PV_VTABLE" ]] || fail "WPS Vtable not found: Vtable.$PV_VTABLE"

shopt -s nullglob
GRIB_FILES=()
for f in "$PV_GRIB_DIR"/*; do
  [[ -f "$f" ]] && GRIB_FILES+=("$f")
done
(("${#GRIB_FILES[@]}" > 0)) || fail "No regular files found in PV_GRIB_DIR."

RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="$RUNS_DIR/$RUN_ID"
WPS_WORK="$RUN_DIR/WPS"
WRF_WORK="$RUN_DIR/WRF"
mkdir -p "$WPS_WORK" "$WRF_WORK" "$ROOT/logs"
LOG="$ROOT/logs/forecast-$RUN_ID.log"
exec > >(tee -a "$LOG") 2>&1
echo "Project Vorticity forecast run: $RUN_ID"
echo "Run directory: $RUN_DIR"
echo "Log: $LOG"

DURATION_FIELDS="$(python3 - "$PV_START" "$PV_END" <<'PY'
import datetime, sys
fmt = "%Y-%m-%d_%H:%M:%S"
try:
    start = datetime.datetime.strptime(sys.argv[1], fmt)
    end = datetime.datetime.strptime(sys.argv[2], fmt)
except ValueError as exc:
    raise SystemExit(f"Date-time must use YYYY-MM-DD_HH:MM:SS: {exc}")
seconds = int((end - start).total_seconds())
if seconds <= 0:
    raise SystemExit("PV_END must be later than PV_START")
days, rem = divmod(seconds, 86400)
hours, rem = divmod(rem, 3600)
minutes, secs = divmod(rem, 60)
print(days, hours, minutes, secs)
PY
)" || fail "Invalid start/end date-time."
read -r RUN_DAYS RUN_HOURS RUN_MINUTES RUN_SECONDS <<< "$DURATION_FIELDS"
TOTAL_SECONDS=$((RUN_DAYS*86400 + RUN_HOURS*3600 + RUN_MINUTES*60 + RUN_SECONDS))
(( TOTAL_SECONDS % PV_INTERVAL_SECONDS == 0 )) || fail "Forecast duration must be divisible by PV_INTERVAL_SECONDS."

cat > "$WPS_WORK/namelist.wps" <<EOF
&share
 wrf_core = 'ARW',
 max_dom = 1,
 start_date = '$PV_START',
 end_date   = '$PV_END',
 interval_seconds = $PV_INTERVAL_SECONDS,
 io_form_geogrid = 2,
/
&geogrid
 parent_id         = 1,
 parent_grid_ratio = 1,
 i_parent_start    = 1,
 j_parent_start    = 1,
 e_we              = $PV_E_WE,
 e_sn              = $PV_E_SN,
 geog_data_res     = '$PV_GEOG_RES',
 dx = $PV_DX,
 dy = $PV_DY,
 map_proj = 'lambert',
 ref_lat   = $PV_CENTER_LAT,
 ref_lon   = $PV_CENTER_LON,
 truelat1  = $PV_TRUELAT1,
 truelat2  = $PV_TRUELAT2,
 stand_lon = $PV_STAND_LON,
 geog_data_path = '$WPS_WORK/WPS_GEOG',
/
&ungrib
 out_format = 'WPS',
 prefix = 'FILE',
/
&metgrid
 fg_name = 'FILE',
 io_form_metgrid = 2,
/
EOF

cat > "$WRF_WORK/namelist.input" <<EOF
&time_control
 run_days                            = $RUN_DAYS,
 run_hours                           = $RUN_HOURS,
 run_minutes                         = $RUN_MINUTES,
 run_seconds                         = $RUN_SECONDS,
 start_year                          = ${PV_START:0:4},
 start_month                         = ${PV_START:5:2},
 start_day                           = ${PV_START:8:2},
 start_hour                          = ${PV_START:11:2},
 start_minute                        = ${PV_START:14:2},
 start_second                        = ${PV_START:17:2},
 end_year                            = ${PV_END:0:4},
 end_month                           = ${PV_END:5:2},
 end_day                             = ${PV_END:8:2},
 end_hour                            = ${PV_END:11:2},
 end_minute                          = ${PV_END:14:2},
 end_second                          = ${PV_END:17:2},
 interval_seconds                    = $PV_INTERVAL_SECONDS,
 input_from_file                     = .true.,
 history_interval                    = $PV_HISTORY_MINUTES,
 frames_per_outfile                  = 1,
 restart                             = .false.,
 io_form_history                     = 2,
 io_form_restart                     = 2,
 io_form_input                       = 2,
 io_form_boundary                    = 2,
/
&domains
 time_step                           = $PV_TIME_STEP,
 time_step_fract_num                 = 0,
 time_step_fract_den                 = 1,
 max_dom                             = 1,
 e_we                                = $PV_E_WE,
 e_sn                                = $PV_E_SN,
 e_vert                              = 45,
 p_top_requested                     = 5000,
 num_metgrid_levels                  = $PV_NUM_METGRID_LEVELS,
 num_metgrid_soil_levels             = $PV_NUM_METGRID_SOIL_LEVELS,
 dx                                  = $PV_DX,
 dy                                  = $PV_DY,
 grid_id                             = 1,
 parent_id                           = 0,
 i_parent_start                      = 1,
 j_parent_start                      = 1,
 parent_grid_ratio                   = 1,
 parent_time_step_ratio              = 1,
 feedback                            = 0,
 smooth_option                       = 0,
/
&physics
 mp_physics                          = 8,
 ra_lw_physics                       = 4,
 ra_sw_physics                       = 4,
 radt                                = 15,
 sf_sfclay_physics                   = 1,
 sf_surface_physics                  = 2,
 bl_pbl_physics                      = 1,
 bldt                                = 0,
 cu_physics                          = 1,
 cudt                                = 5,
 isfflx                              = 1,
 ifsnow                              = 1,
 icloud                              = 1,
 surface_input_source                = 1,
 num_soil_layers                     = $PV_NUM_SOIL_LAYERS,
/
&dynamics
 w_damping                           = 1,
 diff_opt                            = 1,
 km_opt                              = 4,
 damp_opt                            = 3,
 zdamp                               = 5000.,
 dampcoef                            = 0.2,
 khdif                               = 0,
 kvdif                               = 0,
 non_hydrostatic                     = .true.,
/
&bdy_control
 spec_bdy_width                      = 5,
 specified                           = .true.,
/
&namelist_quilt
 nio_tasks_per_group                 = 0,
 nio_groups                          = 1,
/
EOF

echo "[1/6] Preparing WPS work directory..."
cp "$WPS_DIR/geogrid.exe" "$WPS_DIR/ungrib.exe" "$WPS_DIR/metgrid.exe" "$WPS_WORK/"
cp -a "$WPS_DIR/geogrid" "$WPS_WORK/"
cp -a "$WPS_DIR/ungrib" "$WPS_WORK/"
cp -a "$WPS_DIR/metgrid" "$WPS_WORK/"
cp "$WPS_DIR/link_grib.csh" "$WPS_WORK/"
cp "$WPS_DIR/ungrib/Variable_Tables/Vtable.$PV_VTABLE" "$WPS_WORK/Vtable"
cd "$WPS_WORK"
ln -sfn "$PV_GEOG_DIR" ./WPS_GEOG
echo "[2/6] Running geogrid..."
./geogrid.exe
echo "[3/6] Linking GRIB files and running ungrib..."
./link_grib.csh "${GRIB_FILES[@]}"
./ungrib.exe
echo "[4/6] Running metgrid..."
./metgrid.exe
MET_FILES=(met_em.d01.*.nc)
(("${#MET_FILES[@]}" > 0)) || fail "metgrid produced no met_em files."
echo "[5/6] Preparing WRF run directory..."
cp -an "$WRF_DIR/run/." "$WRF_WORK/"
cp "$WRF_DIR/main/real.exe" "$WRF_DIR/main/wrf.exe" "$WRF_WORK/"
cp "$WPS_WORK"/met_em.d01.*.nc "$WRF_WORK/"
cd "$WRF_WORK"
ulimit -s unlimited || true
export OMP_NUM_THREADS=1
echo "[5/6] Running real.exe with $PV_MPI_RANKS MPI rank(s)..."
mpirun -np "$PV_MPI_RANKS" ./real.exe
[[ -s wrfinput_d01 && -s wrfbdy_d01 ]] || fail "real.exe did not create wrfinput_d01 and wrfbdy_d01."
echo "[6/6] Running wrf.exe..."
mpirun -np "$PV_MPI_RANKS" ./wrf.exe
shopt -s nullglob
OUTPUTS=(wrfout_d01_*)
(("${#OUTPUTS[@]}" > 0)) || fail "wrf.exe completed without producing wrfout output."
echo "FORECAST COMPLETE"
echo "Output files: $WRF_WORK/wrfout_d01_*"
echo "Run folder: $RUN_DIR"
echo "Log: $LOG"
