import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-theme-symbolic"
        source: "ConfigTheme.qml"
    }

    ConfigCategory {
        name: i18n("Displays")
        icon: "video-display-symbolic"
        source: "ConfigDisplays.qml"
    }
}
