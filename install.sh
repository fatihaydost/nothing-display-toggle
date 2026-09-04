#!/bin/bash
# Install (or upgrade) the widget for the current user.
set -euo pipefail

ID="io.github.fatihaydost.displaytoggle"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/package"

if ! command -v kpackagetool6 >/dev/null; then
    echo "kpackagetool6 not found — this widget needs KDE Plasma 6." >&2
    exit 1
fi

if kpackagetool6 --type Plasma/Applet --show "$ID" >/dev/null 2>&1; then
    echo "Upgrading $ID ..."
    kpackagetool6 --type Plasma/Applet --upgrade "$SRC"
else
    echo "Installing $ID ..."
    kpackagetool6 --type Plasma/Applet --install "$SRC"
fi

echo
echo "Done. Add it from: right-click the desktop -> Add Widgets... -> Nothing Display Toggle"
echo "If it is not listed yet, run: systemctl --user restart plasma-plasmashell.service"
