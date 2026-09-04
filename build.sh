#!/bin/bash
# Assemble both packages from shared/ + <pkg>/ into build/, then zip each one
# into a distributable .plasmoid (a plain zip of the package directory).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 - "$ROOT" <<'PY'
import json, pathlib, shutil, sys, zipfile

root = pathlib.Path(sys.argv[1])
shared = root / "shared"
build = root / "build"
if build.exists():
    shutil.rmtree(build)

# package directory -> archive name
PACKAGES = {
    "desktop": "nothing-display-toggle",
    "panel": "nothing-display-toggle-panel",
}

for src_name, out_name in PACKAGES.items():
    src = root / src_name
    stage = build / src_name

    # shared first, then the package's own files on top so they win a collision
    shutil.copytree(shared / "ui", stage / "contents" / "ui")
    shutil.copytree(shared / "fonts", stage / "contents" / "fonts")
    shutil.copytree(src, stage, dirs_exist_ok=True)

    meta = json.loads((stage / "metadata.json").read_text())["KPlugin"]
    out = root / f"{out_name}.plasmoid"
    out.unlink(missing_ok=True)

    files = sorted(p for p in stage.rglob("*") if p.is_file())
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for f in files:
            z.write(f, f.relative_to(stage).as_posix())

    print(f"Built {out.name}  ({meta['Id']}, version {meta['Version']})")
    for f in files:
        print(f"  {f.relative_to(stage).as_posix()}  ({f.stat().st_size} bytes)")
    print()
PY
