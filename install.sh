#!/bin/bash
# Build both packages and install (or upgrade) them for the current user.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v kpackagetool6 >/dev/null; then
    echo "kpackagetool6 not found — these widgets need KDE Plasma 6." >&2
    exit 1
fi

"$ROOT/build.sh" >/dev/null

install_one() {
    local dir="$1"
    local id
    id="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["KPlugin"]["Id"])' \
          "$ROOT/build/$dir/metadata.json")"

    if kpackagetool6 --type Plasma/Applet --show "$id" >/dev/null 2>&1; then
        echo "Upgrading $id ..."
        kpackagetool6 --type Plasma/Applet --upgrade "$ROOT/build/$dir"
    else
        echo "Installing $id ..."
        kpackagetool6 --type Plasma/Applet --install "$ROOT/build/$dir"
    fi
}

install_one desktop
install_one panel

echo
echo "Done. Two widgets are now available:"
echo "  Nothing Display Toggle           -> right-click the desktop -> Add Widgets..."
echo "  Nothing Display Toggle (Panel)   -> right-click the panel   -> Add Widgets..."
echo "If they are not listed yet, run: systemctl --user restart plasma-plasmashell.service"
