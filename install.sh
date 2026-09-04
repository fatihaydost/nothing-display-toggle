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
echo

# Plasma loads an applet's QML once and keeps it for the life of the shell, so a
# widget already on screen goes on running the old code until Plasma restarts.
# The settings dialog is read fresh from disk, which makes this confusing: new
# pages appear while the widget itself ignores them.
if [[ "${1:-}" == "--reload" ]]; then
    echo "Restarting Plasma so a widget already on screen picks up the new code ..."
    systemctl --user restart plasma-plasmashell.service
    echo "Done."
else
    echo "A widget already on your desktop or panel is still running the old code."
    echo "Restart Plasma to pick this up  ->  ./install.sh --reload"
    echo "                              or  ->  systemctl --user restart plasma-plasmashell.service"
fi
