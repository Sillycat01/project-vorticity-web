#!/usr/bin/env python3
"""Diagnostic report for Project Vorticity; read-only."""
from pathlib import Path
import os, shutil, platform, subprocess
root = Path(os.environ.get("PV_ROOT", Path.home() / "ProjectVorticity"))
source = Path(os.environ.get("PV_SRC", root / "src"))
print("Project Vorticity diagnostics")
print(f"Platform: {platform.platform()}")
print(f"Root: {root}")
for item in ("WRF", "WPS"):
    p = source / item
    print(f"{item} source: {'FOUND' if p.exists() else 'missing'} ({p})")
    if p.exists():
        checks = {"WRF": ["main/real.exe", "main/wrf.exe"], "WPS": ["geogrid.exe", "ungrib.exe", "metgrid.exe"]}[item]
        for exe in checks:
            print(f"  {exe}: {'present' if (p / exe).exists() else 'missing'}")
for cmd in ("gcc", "gfortran", "git", "make", "mpif90", "nc-config", "nf-config"):
    print(f"{cmd}: {shutil.which(cmd) or 'not found'}")
try:
    print("Disk free at home (bytes):", shutil.disk_usage(Path.home()).free)
except OSError as exc:
    print("Disk status unavailable:", exc)
