#!/bin/bash
# Install (or upgrade) the widget for the current user.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ID="io.github.fatihaydost.displaytoggle"
OLD_PANEL_ID="io.github.fatihaydost.displaytoggle.panel"

if ! command -v kpackagetool6 >/dev/null; then
    echo "kpackagetool6 not found — this widget needs KDE Plasma 6." >&2
    exit 1
fi

upgraded=0
if kpackagetool6 --type Plasma/Applet --show "$ID" >/dev/null 2>&1; then
    echo "Upgrading $ID ..."
    kpackagetool6 --type Plasma/Applet --upgrade "$ROOT/package"
    upgraded=1
else
    echo "Installing $ID ..."
    kpackagetool6 --type Plasma/Applet --install "$ROOT/package"
fi

# Up to 1.0.x the panel form was a second package. It is part of this one now:
# drop the old package, and point any copy still on a panel at the merged one.
# Its settings live under the same keys, so they carry over untouched.
APPLETSRC="${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc"
migrate_panel_copies=0
if kpackagetool6 --type Plasma/Applet --show "$OLD_PANEL_ID" >/dev/null 2>&1; then
    echo "Removing the old separate panel package ($OLD_PANEL_ID) ..."
    kpackagetool6 --type Plasma/Applet --remove "$OLD_PANEL_ID"
fi
if [[ -f "$APPLETSRC" ]] && grep -q "^plugin=$OLD_PANEL_ID\$" "$APPLETSRC"; then
    migrate_panel_copies=1
fi

echo
echo "Done. Right-click the desktop or the panel -> Add Widgets... -> Nothing Display Toggle"
echo

# Plasma loads an applet's QML once and keeps it for the life of the shell, so a
# widget already on screen goes on running the old code until Plasma restarts.
# The settings dialog is read fresh from disk, which makes this confusing: new
# pages appear while the widget itself ignores them.
if [[ "${1:-}" == "--reload" ]]; then
    echo "Restarting Plasma so a widget already on screen picks up the new code ..."
    # plasmashell is a systemd user unit on a standard Plasma 6 session; fall
    # back to the plain process when a session started it by hand
    if systemctl --user is-active --quiet plasma-plasmashell.service; then
        stop_shell()  { systemctl --user stop plasma-plasmashell.service; }
        start_shell() { systemctl --user start plasma-plasmashell.service; }
    else
        stop_shell()  { kquitapp6 plasmashell 2>/dev/null || pkill -x plasmashell || true; sleep 1; }
        start_shell() { setsid plasmashell >/dev/null 2>&1 < /dev/null & }
    fi
    stop_shell
    if (( migrate_panel_copies )); then
        # the shell writes this file back on exit, so edit it only while it is down
        sed -i "s/^plugin=$OLD_PANEL_ID\$/plugin=$ID/" "$APPLETSRC"
        echo "Pointed the panel copy at the merged widget."
    fi
    start_shell
    echo "Done."
elif (( upgraded || migrate_panel_copies )); then
    echo "A widget already on your desktop or panel is still running the old code."
    echo "Restart Plasma to pick this up  ->  ./install.sh --reload"
    echo "                              or  ->  systemctl --user restart plasma-plasmashell.service"
    if (( migrate_panel_copies )); then
        echo
        echo "A copy of the old panel widget is still on a panel and will show as missing."
        echo "./install.sh --reload moves it over to the merged widget, settings included."
    fi
fi
