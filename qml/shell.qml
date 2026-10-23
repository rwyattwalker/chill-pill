pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets
import Quickshell.Services.UPower
import Quickshell.Services.Notifications
import "panels"

ShellRoot {
    id: root

    property var primaryBox: null

    function closeTransientSurfaces(targetBox) {
        if (!targetBox)
            return;

        targetBox.controlCenter = false;
        targetBox.miniDashboard = false;
        targetBox.cliphistOpen = false;
        targetBox.appLauncher = false;
        targetBox.wallpaperSwitcherOpen = false;
    }

    GlobalShortcut {
        appid: "nix-pill"
        name: "togglePill"
        description: "Toggle NixPill"

        onPressed: {
            if (!root.primaryBox)
                return;

            root.pillShown = !root.pillShown;
            root.closeTransientSurfaces(root.primaryBox);
        }
    }

    GlobalShortcut {
        appid: "nix-pill"
        name: "controlCenter"
        description: "Toggle NixPill control center"

        onPressed: {
            if (!root.primaryBox)
                return;

            root.primaryBox.controlCenter = !root.primaryBox.controlCenter;
            root.primaryBox.miniDashboard = false;
            root.primaryBox.cliphistOpen = false;
            root.primaryBox.appLauncher = false;
            root.primaryBox.wallpaperSwitcherOpen = false;
        }
    }

    GlobalShortcut {
        appid: "nix-pill"
        name: "wallpaperSwitcher"
        description: "Toggle NixPill wallpaper switcher"
        onPressed: {
            if (!root.primaryBox)
                return;

            root.primaryBox.controlCenter = false;
            root.primaryBox.miniDashboard = false;
            root.primaryBox.cliphistOpen = false;
            root.primaryBox.appLauncher = false;
            root.primaryBox.wallpaperSwitcherOpen = !root.primaryBox.wallpaperSwitcherOpen;
        }
    }

    GlobalShortcut {
        appid: "nix-pill"
        name: "cliphist"
        description: "Toggle NixPill cliphist"
        onPressed: {
            if (!root.primaryBox)
                return;

            root.primaryBox.controlCenter = false;
            root.primaryBox.miniDashboard = false;
            root.primaryBox.cliphistOpen = !root.primaryBox.cliphistOpen;
            root.primaryBox.appLauncher = false;
            root.primaryBox.wallpaperSwitcherOpen = false;
        }
    }

    GlobalShortcut {
        appid: "nix-pill"
        name: "minidash"
        description: "Toggle NixPill miniDashboard"
        onPressed: {
            if (!root.primaryBox)
                return;

            root.primaryBox.controlCenter = false;
            root.primaryBox.miniDashboard = !root.primaryBox.miniDashboard;
            root.primaryBox.cliphistOpen = false;
            root.primaryBox.appLauncher = false;
            root.primaryBox.wallpaperSwitcherOpen = false;
        }
    }
    GlobalShortcut {
        appid: "nix-pill"
        name: "launcher"
        description: "Toggle NixPill app launcher"
        onPressed: {
            if (!root.primaryBox)
                return;

            root.primaryBox.controlCenter = false;
            root.primaryBox.miniDashboard = false;
            root.primaryBox.cliphistOpen = false;
            root.primaryBox.appLauncher = !root.primaryBox.appLauncher;
            root.primaryBox.wallpaperSwitcherOpen = false;
        }
    }

    IpcHandler {
        target: "cliphist"
        function toggle(): void {
            if (!root.primaryBox)
                return;

            root.primaryBox.controlCenter = false;
            root.primaryBox.miniDashboard = false;
            root.primaryBox.cliphistOpen = !root.primaryBox.cliphistOpen;
            root.primaryBox.appLauncher = false;
            root.primaryBox.wallpaperSwitcherOpen = false;
        }
        function show(): void {
            if (!root.primaryBox)
                return;

            root.primaryBox.controlCenter = false;
            root.primaryBox.miniDashboard = false;
            root.primaryBox.cliphistOpen = true;
        }
        function hide(): void {
            if (root.primaryBox)
                root.primaryBox.cliphistOpen = false;
        }
    }

    IpcHandler {
        target: "controlCenter"
        function toggle(): void {
            if (!root.primaryBox)
                return;

            root.primaryBox.controlCenter = !root.primaryBox.controlCenter;
            root.primaryBox.miniDashboard = false;
            root.primaryBox.cliphistOpen = false;
            root.primaryBox.appLauncher = false;
            root.primaryBox.wallpaperSwitcherOpen = false;
        }
        function show(): void {
            if (!root.primaryBox)
                return;

            root.primaryBox.controlCenter = true;
            root.primaryBox.miniDashboard = false;
            root.primaryBox.cliphistOpen = false;
        }
        function hide(): void {
            if (root.primaryBox)
                root.primaryBox.controlCenter = false;
        }
    }

    IpcHandler {
        target: "miniDashboard"
        function toggle(): void {
            if (!root.primaryBox)
                return;

            root.primaryBox.controlCenter = false;
            root.primaryBox.miniDashboard = !root.primaryBox.miniDashboard;
            root.primaryBox.cliphistOpen = false;
            root.primaryBox.appLauncher = false;
            root.primaryBox.wallpaperSwitcherOpen = false;
        }
        function show(): void {
            if (!root.primaryBox)
                return;

            root.primaryBox.controlCenter = false;
            root.primaryBox.miniDashboard = true;
            root.primaryBox.cliphistOpen = false;
            root.primaryBox.wallpaperSwitcherOpen = false;
        }
        function hide(): void {
            if (root.primaryBox)
                root.primaryBox.miniDashboard = false;
        }
    }

    IpcHandler {
        target: "appLauncher"
        function toggle(): void {
            if (!root.primaryBox)
                return;

            root.primaryBox.controlCenter = false;
            root.primaryBox.miniDashboard = false;
            root.primaryBox.cliphistOpen = false;
            root.primaryBox.appLauncher = !root.primaryBox.appLauncher;
            root.primaryBox.wallpaperSwitcherOpen = false;
        }
        function show(): void {
            if (!root.primaryBox)
                return;

            root.primaryBox.controlCenter = false;
            root.primaryBox.miniDashboard = false;
            root.primaryBox.cliphistOpen = false;
            root.primaryBox.appLauncher = true;
        }
        function hide(): void {
            if (!root.primaryBox)
                return;

            root.primaryBox.appLauncher = false;
            root.primaryBox.wallpaperSwitcherOpen = false;
        }
    }

    IpcHandler {
        target: "wallpaperSwitcher"
        function toggle(): void {
            if (!root.primaryBox)
                return;

            root.primaryBox.controlCenter = false;
            root.primaryBox.miniDashboard = false;
            root.primaryBox.cliphistOpen = false;
            root.primaryBox.appLauncher = false;
            root.primaryBox.wallpaperSwitcherOpen = !root.primaryBox.wallpaperSwitcherOpen;
        }
        function show(): void {
            if (!root.primaryBox)
                return;

            root.primaryBox.controlCenter = false;
            root.primaryBox.miniDashboard = false;
            root.primaryBox.cliphistOpen = false;
            root.primaryBox.appLauncher = false;
            root.primaryBox.wallpaperSwitcherOpen = true;
        }
        function hide(): void {
            if (!root.primaryBox)
                return;

            root.primaryBox.appLauncher = false;
            root.primaryBox.wallpaperSwitcherOpen = false;
        }
    }

    property bool pillShown: true
    property string bg: Theme.bg
    property string fg: Theme.fg
    property string fontFamily: Theme.fontFamily
    property int avatarSize: 48
    property int buttonSize: 20
    property string buttonBg: "#353535"
    property string buttonHoverBg: "#bababa"
    property int buttonHoverSpeed: 120
    property int buttonctlRadius: 6

    property bool notifFullscreenMode: false
    property bool fullscreenActive: ToplevelManager.activeToplevel && ToplevelManager.activeToplevel.fullscreen

    // osd ui
    property int osdInWidth: 120
    property real osdInHeight: 3.7
    property int osdBarRadius: 2
    property int osdSpeed: 60 // how fast bar fill/unfill
    property int osdWidth: 220
    property int osdHeight: 40

    readonly property int notifMaxHeight: 97

    // media player related
    property bool mediaAutoOpened: false

    Variants {
        model: Quickshell.screens

        PillPanel {
            property var modelData
            screen: modelData
            shellRoot: root
            mprisModule: mprisModule
            countdownModule: countdownModule
            notificationModule: notificationModule
        }
    }

    MprisModule {
        id: mprisModule
        visible: false
    }

    CountdownModule {
        id: countdownModule
        visible: false
    }

    NotificationServer {
        id: notifServer
        keepOnReload: false
        onNotification: notif => {
            notif.tracked = true;
            notificationModule.enqueue(notif);
        }
    }

    NotificationModule {
        id: notificationModule
        visible: false
    }

    Variants {
        model: Quickshell.screens

        FullscreenOsd {
            id: fsNotif
            property var modelData
            property var displayNotif: notificationModule.current

            screen: modelData
            active: notificationModule.active && root.notifFullscreenMode
            visible: root.notifFullscreenMode
            cardWidth: 300
            cardHeight: 52

            RowLayout {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    text: String.fromCodePoint(0xf0f3)
                    color: Theme.fg
                    font {
                        family: Theme.nerdFontFamily
                        pixelSize: 14
                    }
                    visible: cardIcon.status !== Image.Ready
                }

                Image {
                    id: cardIcon
                    Layout.preferredWidth: 23
                    Layout.preferredHeight: 23
                    fillMode: Image.PreserveAspectCrop
                    source: {
                        if (fsNotif.displayNotif && fsNotif.displayNotif.image)
                            return fsNotif.displayNotif.image;
                        if (fsNotif.displayNotif && fsNotif.displayNotif.appIcon) {
                            return fsNotif.displayNotif.appIcon.startsWith("/") ? "file://" + fsNotif.displayNotif.appIcon : "image://icon/" + fsNotif.displayNotif.appIcon;
                        }
                        return "";
                    }
                    sourceSize: Qt.size(23, 23)
                    visible: status === Image.Ready
                }

                ColumnLayout {
                    spacing: 3

                    Text {
                        text: fsNotif.displayNotif ? fsNotif.displayNotif.summary : ""
                        color: Theme.fg
                        font {
                            family: Theme.fontFamily
                            pixelSize: 10
                            weight: 700
                        }
                        elide: Text.ElideRight
                        Layout.maximumWidth: 200
                    }

                    Text {
                        text: fsNotif.displayNotif ? fsNotif.displayNotif.body : ""
                        color: "#9b9b9b"
                        font {
                            family: Theme.fontFamily
                            pixelSize: 9
                        }
                        elide: Text.ElideRight
                        visible: text !== ""
                        Layout.maximumWidth: 200
                    }
                }
            }
        }
    }

    Connections {
        target: notificationModule
        function onActiveChanged() {
            if (notificationModule.active) {
                root.notifFullscreenMode = root.fullscreenActive;
            } else {
                root.notifFullscreenMode = false;
            }
        }
    }
}
