#!/bin/bash
# Build a distributable .plasmoid archive (a plain zip of the package directory).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 - "$ROOT" <<'PY'
import json, pathlib, sys, zipfile

root = pathlib.Path(sys.argv[1])
pkg = root / "package"
version = json.loads((pkg / "metadata.json").read_text())["KPlugin"]["Version"]
out = root / "nothing-display-toggle.plasmoid"

if out.exists():
    out.unlink()

files = sorted(p for p in pkg.rglob("*") if p.is_file())
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for f in files:
        z.write(f, f.relative_to(pkg).as_posix())

print(f"Built {out} (version {version})")
for f in files:
    print(f"  {f.relative_to(pkg).as_posix()}  ({f.stat().st_size} bytes)")
PY
