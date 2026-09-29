import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.configuration

ConfigModel {
    // First, because Plasma opens the dialog on the first page in this list
    // even when it is hidden: with Panel on top, a desktop copy opened onto a
    // page its sidebar does not show.
    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-theme-symbolic"
        source: "ConfigTheme.qml"
    }

    // only meaningful when the widget sits on a panel
    ConfigCategory {
        name: i18n("Panel")
        icon: "configure-symbolic"
        source: "ConfigPanel.qml"
        visible: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
              || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    }

    ConfigCategory {
        name: i18n("Displays")
        icon: "video-display-symbolic"
        source: "ConfigDisplays.qml"
    }
}
