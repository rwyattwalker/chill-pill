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
import ".."

PanelWindow {
    id: panelWindow
    required property var shellRoot
    required property var mprisModule
    required property var countdownModule
    required property var notificationModule
    property var modelData
    screen: modelData
    WlrLayershell.layer: WlrLayershell.Top
    WlrLayershell.keyboardFocus: (box.cliphistOpen || box.appLauncher || box.wallpaperSwitcherOpen) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    implicitHeight: 482

    Component.onCompleted: shellRoot.primaryBox = box
    Component.onDestruction: {
        if (shellRoot.primaryBox === box)
            shellRoot.primaryBox = null;
    }

    anchors {
        top: true
        left: true
        right: true
    }

    margins.top: Config.pillTopMargin

    // fixed gap of the active window for the top bar
    exclusiveZone: shellRoot.pillShown ? Config.pillBottomMargin : 0
    color: "transparent"

    // Mask input to only the capsule
    mask: Region {
        Region {
            intersection: Intersection.Combine
            x: Math.floor(box.x)
            y: Math.floor(box.y)
            width: panelWindow.shellRoot.pillShown ? Math.ceil(box.width) : 0
            height: panelWindow.shellRoot.pillShown ? Math.ceil(box.height) : 0
        }
        Region {
            intersection: Intersection.Combine
            x: Math.floor(calendarPopup.x)
            y: Math.floor(calendarPopup.y)
            width: calendarPopup.shown ? Math.ceil(calendarPopup.width) : 0
            height: calendarPopup.shown ? Math.ceil(calendarPopup.height) : 0
        }
        Region {
            intersection: Intersection.Combine
            x: weatherPopupLoader.item ? Math.floor(weatherPopupLoader.item.x) : 0
            y: weatherPopupLoader.item ? Math.floor(weatherPopupLoader.item.y) : 0
            width: weatherPopupLoader.item && weatherPopupLoader.item.shown ? Math.ceil(weatherPopupLoader.item.width) : 0
            height: weatherPopupLoader.item && weatherPopupLoader.item.shown ? Math.ceil(weatherPopupLoader.item.height) : 0
        }
    }

    // main dynamic pill bar
    Rectangle {
        id: box
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: (!shellRoot.fullscreenActive && !shellRoot.notifFullscreenMode && shellRoot.pillShown) ? 1 : 0
        visible: opacity > 0
        clip: true
        property real slideY: shellRoot.pillShown ? 0 : -box.height - Config.pillTopMargin
        property real squashY: shellRoot.pillShown ? 1.0 : 0.65
        property real squashX: shellRoot.pillShown ? 1.0 : 0.96

        transform: [
            Translate {
                y: box.slideY
            },
            Scale {
                origin.x: box.width / 2
                origin.y: 0
                xScale: box.squashX
                yScale: box.squashY
            }
        ]

        Behavior on slideY {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutExpo
            }
        }

        Behavior on squashY {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutBack
                easing.overshoot: 0.7
            }
        }

        Behavior on squashX {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutExpo
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
            }
        }

        property bool appLauncher: false
        property bool hovered: false
        property bool miniDashboard: false
        property bool controlCenter: false
        property bool cliphistOpen: false
        property bool wallpaperSwitcherOpen: false

        property var battery: UPower.displayDevice
        property bool hasBattery: battery.isLaptopBattery && battery.isPresent
        property bool charging: hasBattery && battery.state === UPowerDeviceState.Charging
        readonly property string batteryIconColor: box.charging || box.batteryLevel > 30 ? "#4bd25c" : box.batteryLevel <= 15 ? "#e22323" : "#eecc47"
        readonly property int batteryLevel: hasBattery ? Math.round(battery.percentage * 100) : 0
        // battery icon on laptops, plug icon on desktops
        readonly property string batteryIcon: {
            if (!hasBattery)
                return String.fromCodePoint(0xf06a5) + " "; // nf-md-power_plug
            const icons = [0xf0083, 0xf007a, 0xf007d, 0xf007c, 0xf007d, 0xf007e, 0xf007f, 0xf0082, 0xf0081, 0xf0079];
            const base = String.fromCodePoint(icons[Math.min(Math.floor(batteryLevel / 10), 9)]);
            return charging ? base + String.fromCodePoint(0xf140b) : base;
        }

        onChargingChanged: {
            if (!box.controlCenter)
                box.activeOsd = "battery";
            osdHideTimer.interval = Config.osdDuration;
            osdHideTimer.restart();
            console.log("charging:", box.charging, "level:", box.batteryLevel);
        }

        property string accent: Theme.accent

        // control center UI
        property real ccButtonBorderWidth: 1
        property string ccButtonBorderColor: "#202020"
        property int ccButtonWidth: 110
        property int ccButtonHeight: 35
        property int ccButtonRadius: 10
        property string ccButtonBgOff: "#151515"
        property string ccButtonFgOff: "#a8a8a8"
        property int sliderHeight: 4
        property int sliderRadius: 4
        property string sliderColor: "#c9c9c9"
        // invisible extra clickable area above/below the thin slider bars
        // (proportional to the bar height, so it scales with sliderHeight)
        property int sliderHitSlop: sliderHeight * 2
        property int mprisControlsIconSize: 20

        // Explicit control-center dependencies avoid same-name bindings
        // resolving against the child component's own required properties.
        readonly property var controlCenterVolumeModule: volumeModule
        readonly property var controlCenterBrightnessModule: brightnessModule
        readonly property var controlCenterBrightnessSetProc: brightnessSetProc
        readonly property var controlCenterBrightnessThrottle: brightnessThrottle

        property string activeOsd: "" // volume, brightness, timer, battery

        Process {
            id: brightnessSetProc
            running: false
        }

        Timer {
            id: osdHideTimer
            onTriggered: box.activeOsd = ""
        }
        Timer {
            id: brightnessThrottle
            interval: 80
            repeat: false
        }

        onImplicitHeightChanged: {
            heightAnim.stop();
            heightAnim.to = implicitHeight;
            heightAnim.duration = shellRoot.mediaAutoOpened ? 650 : 550;
            heightAnim.start();
        }

        readonly property int notifBump: notificationModule.notifications.length > 0 ? Math.min(controlCenterPanel.notificationListContentHeight + 40, 130) : 0

        // adjust box shape conditionally
        implicitWidth: activeOsd === "battery" ? shellRoot.osdWidth : box.activeOsd === "timer" ? shellRoot.osdWidth : (notificationModule.active && !shellRoot.notifFullscreenMode && !controlCenter) ? 305 : controlCenter ? 390 : box.activeOsd === "volume" ? shellRoot.osdWidth : box.activeOsd === "brightness" ? shellRoot.osdWidth : shellRoot.mediaAutoOpened ? 340 : appLauncher ? 390 : miniDashboard ? 420 : cliphistOpen ? 460 : wallpaperSwitcherOpen ? 600 : row.implicitWidth + (12 * Config.paddingScale) + (box.hovered ? 68 : 56) * Config.paddingScale

        implicitHeight: activeOsd === "battery" ? shellRoot.osdHeight : activeOsd === "timer" ? shellRoot.osdHeight : (notificationModule.active && !shellRoot.notifFullscreenMode && !controlCenter) ? 52 : controlCenter && mprisModule.hasPlayer ? (240 + notifBump) : controlCenter ? (118 + notifBump) : activeOsd === "volume" ? shellRoot.osdHeight : activeOsd === "brightness" ? shellRoot.osdHeight : shellRoot.mediaAutoOpened ? 90 : cliphistOpen ? 270 : miniDashboard ? 155 : appLauncher ? 410 : wallpaperSwitcherOpen ? 308 : (row.implicitHeight * Config.pillScale) + 10

        radius: notificationModule.active ? 99 : shellRoot.mediaAutoOpened ? 22 : cliphistOpen ? 28 : controlCenter && (notificationModule.notifications.length > 0) ? 28 : controlCenter && mprisModule.hasPlayer ? 25 : controlCenter ? 20 : appLauncher ? 30 : miniDashboard ? 20 : wallpaperSwitcherOpen ? 30 : 20 * Config.pillScale

        Behavior on radius {
            NumberAnimation {
                duration: 225
                easing.type: Easing.OutExpo
            }
        }

        color: shellRoot.mediaAutoOpened ? Theme.bg1 : controlCenter && mprisModule.hasPlayer ? "#1a1a1a" : shellRoot.bg

        onMiniDashboardChanged: {
            if (!box.miniDashboard) {
                calendarPopup.shown = false;
                if (weatherPopupLoader.item)
                    weatherPopupLoader.item.shown = false;
            }
        }

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 225
                easing.type: Easing.OutExpo
            }
        }
        NumberAnimation {
            id: heightAnim
            target: box
            property: "height"
            easing.type: Easing.OutExpo
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            onEntered: box.hovered = true
            onExited: box.hovered = false

            onClicked: mouse => {
                if (shellRoot.mediaAutoOpened)
                    return;

                // restrict control center to only accept left click
                if (box.controlCenter) {
                    if (mouse.button === Qt.LeftButton)
                        box.controlCenter = false;
                    return;
                }

                // same, cliphist accept middle
                if (box.cliphistOpen) {
                    if (mouse.button === Qt.MiddleButton) {
                        box.cliphistOpen = false;
                    }
                    return;
                }

                // mini dashboard accept only right
                if (box.miniDashboard) {
                    if (mouse.button === Qt.RightButton) {
                        box.miniDashboard = false;
                    }
                    return;
                }

                if (box.wallpaperSwitcherOpen) {
                    if (mouse.button !== Qt.LeftButton) {
                        return;
                    }
                }

                if (mouse.button === Qt.LeftButton) {
                    console.log("Left click detected, opening control center");
                    box.controlCenter = !box.controlCenter;
                    shellRoot.mediaAutoOpened = false;
                    box.appLauncher = false;
                    box.wallpaperSwitcherOpen = false;
                    mediaPopupHideTimer.stop();
                }

                if (mouse.button === Qt.MiddleButton) {
                    console.log("Middle click detected, opening cliphist");
                    shellRoot.mediaAutoOpened = false;
                    box.appLauncher = false;
                    box.wallpaperSwitcherOpen = false;
                    box.cliphistOpen = !box.cliphistOpen;
                }

                if (mouse.button === Qt.RightButton) {
                    console.log("Right click detected, opening mini dashboard");
                    shellRoot.mediaAutoOpened = false;
                    box.appLauncher = false;
                    box.wallpaperSwitcherOpen = false;
                    box.miniDashboard = !box.miniDashboard;
                }
            }
        }

        Brightness {
            id: brightnessModule
            visible: false
            onBrightnessUpdated: {
                if (!box.controlCenter)
                    box.activeOsd = "brightness";
                osdHideTimer.interval = Config.osdDuration;
                osdHideTimer.restart();
            }
        }

        // modules in bar
        Item {
            id: row
            implicitWidth: leftGroup.implicitWidth + middleGroup.implicitWidth + rightGroup.implicitWidth + 96
            implicitHeight: Math.max(leftGroup.implicitHeight, middleGroup.implicitHeight, rightGroup.implicitHeight)
            anchors.centerIn: parent
            anchors.fill: parent
            anchors.leftMargin: 28
            anchors.rightMargin: 28
            // spacing: 13 * Config.paddingScale
            opacity: !box.cliphistOpen && !notificationModule.active && !shellRoot.mediaAutoOpened && !box.controlCenter && !box.miniDashboard && box.activeOsd === "" && !box.wallpaperSwitcherOpen && !box.appLauncher ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 100
                }
            }

            RowLayout {
                id: leftGroup
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                Battery {}
                Volume {
                    id: volumeModule
                    onVolumeChanged: {
                        if (!box.controlCenter)
                            box.activeOsd = "volume";
                        osdHideTimer.interval = Config.osdDuration;
                        osdHideTimer.restart();
                    }
                }
                Network {
                    visible: Config.pillModules.networking
                }
            }

            RowLayout {
                id: middleGroup
                anchors.centerIn: parent

                Workspaces {}
            }

            RowLayout {
                id: rightGroup
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                Clock {
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // volume
        OsdBar {
            active: box.activeOsd === "volume"
            icon: volumeModule.icon
            iconColor: volumeModule.muted ? volumeModule.mutedFg : Theme.fg
            percent: volumeModule.vol / 100
            muted: volumeModule.muted
            barWidth: volumeModule.mutedFg ? 90 : 110
            valueText: volumeModule.muted ? "muted" : volumeModule.vol + "%"
        }

        // brightness
        OsdBar {
            active: box.activeOsd === "brightness"
            icon: brightnessModule.icon
            percent: brightnessModule.percent
            valueText: Math.round(brightnessModule.percent * 100) + "%"
            barWidth: 100
        }

        // battery
        OsdBar {
            active: box.activeOsd === "battery"
            icon: box.batteryIcon
            iconColor: box.batteryIconColor
            valueText: box.charging ? "Charging" : "Charging stopped"
            barWidth: 0
            spacing: 5 // gap between battery icon and text
        }

        // timer end
        OsdBar {
            active: box.activeOsd === "timer"
            icon: String.fromCodePoint(0xf1ad1)
            iconColor: "#5892f3"
            valueText: "Timer finished"
            barWidth: 0
            spacing: 5
        }

        // notification
        NotificationPopup {
            active: notificationModule.active && !shellRoot.notifFullscreenMode && box.activeOsd === "" && !box.controlCenter
            notif: notificationModule.current
        }

        // cliphist opens on middle click
        Item {
            anchors.centerIn: parent
            width: box.implicitWidth - 26
            height: box.cliphistOpen ? box.implicitHeight - 26 : 0
            opacity: box.cliphistOpen && !notificationModule.active && box.activeOsd === "" && !shellRoot.mediaAutoOpened && !box.controlCenter ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation {
                        duration: box.cliphistOpen ? 15 : 0
                    }
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutExpo
                    }
                }
            }

            Cliphist {
                id: cliphistPanel
                shown: box.cliphistOpen
                anchors.fill: parent
                onCloseRequested: box.cliphistOpen = false
            }
        }

        // wallpaper switcher
        Item {
            anchors.centerIn: parent
            width: box.implicitWidth - 28
            height: box.wallpaperSwitcherOpen ? 280 : 0
            opacity: box.wallpaperSwitcherOpen && !notificationModule.active && box.activeOsd === "" && !shellRoot.mediaAutoOpened && !box.controlCenter && !box.miniDashboard && !box.cliphistOpen && !box.appLauncher ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation {
                        duration: box.wallpaperSwitcherOpen ? 15 : 0
                    }
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutExpo
                    }
                }
            }
            Loader {
                id: wallpaperLoader
                anchors.fill: parent
                active: box.wallpaperSwitcherOpen
                asynchronous: true
                sourceComponent: WallpaperSwitcher {
                    shown: box.wallpaperSwitcherOpen
                    onCloseRequested: box.wallpaperSwitcherOpen = false
                }
                onLoaded: item.forceActiveFocus()
            }

            Connections {
                target: box
                function onWallpaperSwitcherOpenChanged() {
                    if (box.wallpaperSwitcherOpen && wallpaperLoader.item)
                        wallpaperLoader.item.forceActiveFocus();
                }
            }
        }

        // app launcher opens through IPC
        Item {
            anchors.centerIn: parent
            width: box.implicitWidth - 26
            height: box.appLauncher ? 384 : 0
            opacity: box.appLauncher && !notificationModule.active && box.activeOsd === "" && !shellRoot.mediaAutoOpened && !box.controlCenter && !box.miniDashboard && !box.cliphistOpen ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation {
                        duration: box.appLauncher ? 15 : 0
                    }
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutExpo
                    }
                }
            }

            Loader {
                anchors.fill: parent
                active: box.appLauncher
                asynchronous: true

                sourceComponent: AppLauncher {
                    shown: box.appLauncher
                    onCloseRequested: box.appLauncher = false
                }
            }
        }

        // media popup
        Item {
            anchors.fill: parent
            opacity: box.activeOsd === "" && !notificationModule.active ? 1 : 0
            visible: opacity > 0

            Loader {
                anchors.centerIn: parent
                active: shellRoot.mediaAutoOpened
                asynchronous: true

                sourceComponent: MediaPopup {
                    active: shellRoot.mediaAutoOpened
                    mprisModule: panelWindow.mprisModule
                }
            }
        }

        // control center opens on left click
        ControlCenter {
            id: controlCenterPanel
            anchors.centerIn: parent
            panel: box
            shellRoot: panelWindow.shellRoot
            mprisModule: panelWindow.mprisModule
            notificationModule: panelWindow.notificationModule
            volumeModule: box.controlCenterVolumeModule
            brightnessModule: box.controlCenterBrightnessModule
            brightnessSetProc: box.controlCenterBrightnessSetProc
            brightnessThrottle: box.controlCenterBrightnessThrottle
        }

        // mini dashboard opens on right click
        Item {
            anchors.centerIn: parent
            width: box.implicitWidth - 30
            height: box.miniDashboard ? box.implicitHeight - 30 : 0  // don't fight the animation
            opacity: box.miniDashboard && !shellRoot.mediaAutoOpened && !notificationModule.active && box.activeOsd === "" && !box.cliphistOpen ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation {
                        duration: box.miniDashboard ? 1 : 0
                    }
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutExpo
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        box.miniDashboard = !box.miniDashboard;
                }
            }

            RowLayout {
                // profile picture (display picture)
                ClippingRectangle {
                    id: avatarClip
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.preferredHeight: shellRoot.avatarSize
                    Layout.preferredWidth: shellRoot.avatarSize
                    radius: shellRoot.avatarSize / 2
                    property string imgPath: Config.displayPicture ? "file://" + Config.displayPicture.replace("~", Quickshell.env("HOME")) : ""
                    color: (imgPath === "" || avatarImg.status !== Image.Ready) ? "#454545" : "transparent"

                    Image {
                        id: avatarImg
                        anchors.fill: parent
                        source: avatarClip.imgPath
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: false
                    }
                }

                // username
                Process {
                    id: whoamiProc
                    command: ["sh", "-c", 'whoami']
                    running: true
                    stdout: StdioCollector {
                        onStreamFinished: {
                            whoamiText.text = this.text.trim();
                            whoamiProc.running = false;
                        }
                    }
                }

                // hostname
                Process {
                    id: hostnameProc
                    command: ["sh", "-c", "cat /etc/hostname"]
                    running: true
                    stdout: StdioCollector {
                        onStreamFinished: {
                            hostnameText.text = "(" + this.text.trim() + ")";
                            hostnameProc.running = false;
                        }
                    }
                }

                // uptime
                Process {
                    id: uptimeProc
                    command: ["sh", "-c", 'uptime -p']
                    running: true
                    stdout: StdioCollector {
                        onStreamFinished: uptimeText.text = this.text
                    }
                }

                // uptime refresh every 60 sec
                Timer {
                    interval: 60000
                    running: box.miniDashboard
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: {
                        uptimeProc.running = false;
                        uptimeProc.running = true;
                    }
                }

                // username + uptime stacked
                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter

                    RowLayout {
                        Text {
                            id: whoamiText
                            color: Theme.fg
                            Layout.leftMargin: 10
                            font {
                                family: Theme.fontFamily
                                pixelSize: 13
                                weight: 600
                            }
                        }

                        Text {
                            id: hostnameText
                            color: "#848484"
                            Layout.topMargin: 2
                            font {
                                family: Theme.fontFamily
                                pixelSize: 9
                                weight: 300
                            }
                        }
                    }

                    Text {
                        id: uptimeText
                        color: Theme.fg
                        opacity: 0.6
                        Layout.leftMargin: 10
                        font {
                            family: Theme.fontFamily
                            pixelSize: 8
                            weight: 400
                        }
                    }
                }
            }

            // show battery in mini dashboard too
            Battery {
                fontSize: 14
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 8
                anchors.rightMargin: 12
            }

            // internet protocol information
            IpStatus {
                active: box.miniDashboard
                anchors.left: parent.left
                anchors.leftMargin: 5
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 42
            }

            // bandwidth usage status
            Bandwidth {
                active: box.miniDashboard
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 42
            }

            // rectangle where poweroff, sleep etc. buttons placed
            Rectangle {
                color: "#212121"
                implicitWidth: 15
                implicitHeight: 30
                radius: 8

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 97

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    // lock
                    Rectangle {
                        Layout.preferredWidth: shellRoot.buttonSize
                        Layout.preferredHeight: shellRoot.buttonSize
                        radius: shellRoot.buttonctlRadius
                        color: shellRoot.buttonBg
                        Layout.alignment: Qt.AlignVCenter
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: lockHover.containsMouse ? shellRoot.buttonHoverBg : Theme.fg
                            font.pixelSize: 8
                            Behavior on color {
                                ColorAnimation {
                                    duration: shellRoot.buttonHoverSpeed
                                }
                            }
                        }

                        MouseArea {
                            id: lockHover
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                lockProc.running = false;
                                lockProc.running = true;
                            }
                            hoverEnabled: true
                        }

                        Process {
                            id: lockProc
                            command: ["bash", "-c", Config.screenLockAppCommand]
                            running: false
                        }
                    }

                    // sleep
                    Rectangle {
                        Layout.preferredWidth: shellRoot.buttonSize
                        Layout.preferredHeight: shellRoot.buttonSize
                        radius: shellRoot.buttonctlRadius
                        color: shellRoot.buttonBg
                        Layout.alignment: Qt.AlignVCenter
                        Text {
                            anchors.centerIn: parent
                            text: "󰤄"
                            color: sleepHover.containsMouse ? shellRoot.buttonHoverBg : Theme.fg
                            font.pixelSize: 9
                            Behavior on color {
                                ColorAnimation {
                                    duration: shellRoot.buttonHoverSpeed
                                }
                            }
                        }

                        MouseArea {
                            id: sleepHover
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                sleepProc.running = false;
                                sleepProc.running = true;
                            }
                            hoverEnabled: true
                        }
                        Process {
                            id: sleepProc
                            command: ["bash", "-c", "systemctl suspend"]
                            running: false
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Datetime {
                        id: datetimeItem
                        dateFg: "#aaaaaa"
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    WeatherIndicator {
                        id: weatherIndicatorItem
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // reboot
                    Rectangle {
                        Layout.preferredWidth: shellRoot.buttonSize
                        Layout.preferredHeight: shellRoot.buttonSize
                        radius: shellRoot.buttonctlRadius
                        color: shellRoot.buttonBg
                        Layout.alignment: Qt.AlignVCenter
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: rebootHover.containsMouse ? shellRoot.buttonHoverBg : Theme.fg
                            font.pixelSize: 9
                            Behavior on color {
                                ColorAnimation {
                                    duration: shellRoot.buttonHoverSpeed
                                }
                            }
                        }

                        MouseArea {
                            id: rebootHover
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                rebootProc.running = false;
                                rebootProc.running = true;
                            }
                            hoverEnabled: true
                        }
                        Process {
                            id: rebootProc
                            command: ["bash", "-c", "systemctl reboot"]
                            running: false
                        }
                    }

                    // shutdown
                    Rectangle {
                        Layout.preferredWidth: shellRoot.buttonSize
                        Layout.preferredHeight: shellRoot.buttonSize
                        radius: shellRoot.buttonctlRadius
                        color: shellRoot.buttonBg
                        Layout.alignment: Qt.AlignVCenter
                        Text {
                            anchors.centerIn: parent
                            text: "󰐥"
                            color: shutdownHover.containsMouse ? shellRoot.buttonHoverBg : Theme.fg
                            font.pixelSize: 12
                            Behavior on color {
                                ColorAnimation {
                                    duration: shellRoot.buttonHoverSpeed
                                }
                            }
                        }

                        MouseArea {
                            id: shutdownHover
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                shutdownProc.running = false;
                                shutdownProc.running = true;
                            }
                            hoverEnabled: true
                        }
                        Process {
                            id: shutdownProc
                            command: ["bash", "-c", "systemctl poweroff"]
                            running: false
                        }
                    }
                }
            }
        }
        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }
    }

    // calendar popup box
    CalendarBox {
        id: calendarPopup
    }

    Loader {
        id: weatherPopupLoader
        active: false
        asynchronous: false

        sourceComponent: WeatherPopup {
            panel: box
            onShownChanged: if (!shown)
                closeTimer.start()
        }

        onLoaded: item.shown = true
        Timer {
            id: closeTimer
            interval: 250
            onTriggered: weatherPopupLoader.active = false
        }
    }

    // open calendar when click on date in mini dashboard
    Connections {
        target: datetimeItem
        function onToggleCalendar() {
            console.log("toggleCalendar launched, current opacity:", calendarPopup.opacity);
            calendarPopup.shown = !calendarPopup.shown;
            if (weatherPopupLoader.item)
                weatherPopupLoader.item.shown = false;
        }
    }

    // open weather when click on weather in mini dashboard
    Connections {
        target: weatherIndicatorItem
        function onToggleWeather() {
            if (shellRoot.mediaAutoOpened)
                return;
            if (!weatherPopupLoader.active)
                weatherPopupLoader.active = true;
            else
                weatherPopupLoader.item.shown = !weatherPopupLoader.item.shown;
            calendarPopup.shown = false;
        }
    }

    Connections {
        target: mprisModule
        function onNowPlaying() {
            if (box.controlCenter)
                return;
            if (!box.mediaPopup)
                shellRoot.mediaAutoOpened = true;
            mediaPopupHideTimer.restart();
        }
    }

    Timer {
        id: mediaPopupHideTimer
        interval: Config.mediaPopupDuration
        repeat: false
        onTriggered: {
            if (shellRoot.mediaAutoOpened)
                shellRoot.mediaAutoOpened = false;
        }
    }

    Connections {
        target: countdownModule
        function onTimerFinished() {
            if (!box.controlCenter)
                box.activeOsd = "timer";
            osdHideTimer.interval = 2500;
            osdHideTimer.restart();
        }
    }
}
