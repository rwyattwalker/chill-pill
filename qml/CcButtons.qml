import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

RowLayout {
    id: root

    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    readonly property var activeNetwork: wifiDevice?.networks.values.find(n => n.connected)
    property real buttonBorderWidth
    property string buttonBorderColor
    property real buttonWidth
    property real buttonHeight
    property real buttonRadius
    property color buttonBgOff
    property color buttonFgOff

    property bool notificationPopup: false
    property bool controlCenterOpen: false
    property bool mediaAutoOpened: false
    property bool wifiPanelOpened: false
    property bool hasPlayer: false
    property real playerHeight: 0

    anchors.top: parent.top
    anchors.topMargin: hasPlayer ? playerHeight + 92 : 5
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: 5
    anchors.rightMargin: 5

    onControlCenterOpenChanged: {
        root.wifiDevice.scannerEnabled = true;
        if (!controlCenterOpen)
            root.wifiPanelOpened = false;
    }

    // wifi
    Rectangle {
        id: wifiBtn
        Layout.preferredWidth: root.buttonWidth
        Layout.preferredHeight: root.buttonHeight
        radius: root.buttonRadius
        visible: root.controlCenterOpen && !root.mediaAutoOpened
        color: Networking.wifiEnabled ? (wifiHover.hovered ? Qt.lighter("#212529", 1.2) : "#212529") : (wifiHover.hovered ? Qt.lighter(root.buttonBgOff, 1.3) : root.buttonBgOff)
        border.width: Networking.wifiEnabled ? 0 : root.buttonBorderWidth
        border.color: root.buttonBorderColor
        scale: wifiMouse.pressed ? 0.93 : 1.0
        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 80
                easing.type: Easing.OutQuad
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 5
            Text {
                text: "\uf1eb" // wifi glyph
                color: Networking.wifiEnabled ? "#4282e9" : root.buttonFgOff
                font {
                    family: Theme.nerdFontFamily
                    pixelSize: 14
                }
            }
            Text {
                color: Networking.wifiEnabled ? "#dedede" : root.buttonFgOff
                font {
                    family: Theme.fontFamily
                    pixelSize: 12
                    weight: 400
                }
                elide: Text.ElideRight
                Layout.maximumWidth: 90
            }
        }

        HoverHandler {
            id: wifiHover
        }
        MouseArea {
            id: wifiMouse
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    root.wifiPanelOpened = !root.wifiPanelOpened;
                    if (root.wifiPanelOpened && Networking.wifiEnabled)
                        root.wifiDevice.scannerEnabled = true;
                    return;
                }
                root.wifiDevice.scannerEnabled = true;
            }
        }
    }

    WifiPanel {
        visible: root.wifiPanelOpened
        anchorX: wifiBtn.mapToGlobal(0, 0).x - width  // sit left of the wifi button
        anchorY: wifiBtn.mapToGlobal(0, 0).y
    }

    onNotificationPopupChanged: {
        if (root.notificationPopup)
            root.wifiPanelOpened = false;
    }

    Item {
        Layout.fillWidth: true
    }

    // silent notifications
    Rectangle {
        id: dndBtn
        Layout.preferredWidth: root.buttonWidth
        Layout.preferredHeight: root.buttonHeight
        radius: root.buttonRadius
        visible: root.controlCenterOpen && !root.mediaAutoOpened
        color: notificationModule.dndEnabled ? (dndHover.hovered ? Qt.lighter("#262626", 1.2) : "#262626") : (dndHover.hovered ? Qt.lighter(root.buttonBgOff, 1.3) : root.buttonBgOff)
        border.width: notificationModule.dndEnabled ? 0 : root.buttonBorderWidth
        border.color: root.buttonBorderColor
        scale: dndMouse.pressed ? 0.93 : 1.0
        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 80
                easing.type: Easing.OutQuad
            }
        }

        Text {
            text: String.fromCodePoint(0xf1f6)
            color: notificationModule.dndEnabled ? "#fff9eb" : root.buttonFgOff
            anchors.centerIn: parent
            font {
                family: Theme.nerdFontFamily
                pixelSize: 14
            }
        }
        HoverHandler {
            id: dndHover
        }
        MouseArea {
            id: dndMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: notificationModule.dndEnabled = !notificationModule.dndEnabled
        }
    }

    Item {
        Layout.fillWidth: true
    }

    // timer / countdown
    Rectangle {
        id: timerBtn
        Layout.preferredWidth: root.buttonWidth
        Layout.preferredHeight: root.buttonHeight
        radius: root.buttonRadius
        color: countdownModule.running ? (timerHover.hovered ? Qt.lighter("#212529", 1.2) : "#212529") : (timerHover.hovered ? Qt.lighter(root.buttonBgOff, 1.3) : root.buttonBgOff)
        border.width: countdownModule.running ? 0 : root.buttonBorderWidth
        border.color: root.buttonBorderColor
        scale: timerMouse.pressed ? 0.93 : 1.0
        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 80
                easing.type: Easing.OutQuad
            }
        }
        property int selectedMinutes: 1

        RowLayout {
            anchors.centerIn: parent
            spacing: 5
            Text {
                text: {
                    if (countdownModule.running)
                        return String.fromCodePoint(0xf1ade);
                    if (countdownModule.remainingSeconds > 0)
                        return String.fromCodePoint(0xf1ae0);
                    return String.fromCodePoint(0xf13ab);
                }
                color: countdownModule.running ? "#4490ee" : root.buttonFgOff
                font {
                    family: Theme.nerdFontFamily
                    pixelSize: 14
                }
            }
            Text {
                text: countdownModule.running || countdownModule.remainingSeconds > 0 ? countdownModule.formatted() : timerBtn.selectedMinutes + "m"
                color: countdownModule.running ? "#dedede" : root.buttonFgOff
                font {
                    family: Theme.fontFamily
                    pixelSize: 12
                    weight: 400
                }
            }
        }

        HoverHandler {
            id: timerHover
        }
        MouseArea {
            id: timerMouse
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton) {
                    countdownModule.reset();
                    return;
                }
                if (mouse.button === Qt.RightButton) {
                    if (countdownModule.running || countdownModule.remainingSeconds > 0)
                        return;
                    const presets = Config.timerPresets;
                    const idx = presets.indexOf(timerBtn.selectedMinutes);
                    timerBtn.selectedMinutes = presets[(idx + 1) % presets.length];
                    return;
                }
                if (countdownModule.running) {
                    countdownModule.pause();
                    return;
                }
                if (countdownModule.remainingSeconds > 0) {
                    countdownModule.resume();
                    return;
                }
                countdownModule.start(timerBtn.selectedMinutes);
            }
        }
    }
}
