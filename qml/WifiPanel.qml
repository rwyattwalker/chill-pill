pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

PanelWindow {
    id: root

    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    readonly property var activeNetwork: wifiDevice?.networks.values.find(n => n.connected)
    property var targetNetwork: null
    property string errorMessage: ""
    property real anchorX: 0
    property real anchorY: 0

    anchors.top: true
    anchors.left: true
    margins.top: anchorY
    margins.left: anchorX

    property bool controlCenter: false
    property string passwordPromptSsid: ""
    property bool passwordPromptVisible: false
    property string passwordValue: ""

    // keyboard focus for password prompt
    WlrLayershell.keyboardFocus: passwordPromptVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 270
    implicitHeight: 348
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 40
        anchors.rightMargin: 30
        color: "#1c1c1c"
        radius: 26

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 13

            Text {
                text: "Wi-Fi"
                color: "#d2d2d2"
                font {
                    family: Theme.fontFamily
                    pixelSize: 14
                    bold: true
                }
                Layout.leftMargin: 5
            }

            Text {
                visible: !Networking.wifiEnabled
                text: "Turn on the Wi-Fi to see networks."
                color: "#949494"
                font {
                    family: Theme.fontFamily
                    pixelSize: 11
                }
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.leftMargin: 5
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: networkColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: networkColumn
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: root.wifiDevice?.networks ?? null
                        delegate: Rectangle {
                            id: delegate
                            required property var modelData
                            property string ssid: ""
                            Component.onCompleted: {
                                delegate.modelData.connectionFailed.connect(reason => {
                                    if (reason == ConnectionFailReason.NoSecrets) {
                                        root.passwordPromptSsid = delegate.modelData.name;
                                        root.passwordPromptVisible = true;

                                        root.targetNetwork = delegate.modelData;
                                    }
                                });
                            }
                            width: networkColumn.width
                            height: 45
                            radius: 16
                            color: modelData.connected ? "#4173c4" : (networkMouse.containsMouse ? "#313131" : "#252525")
                            border.color: modelData.connected ? "" : "#2f2f2f"
                            border.width: modelData.connected ? 0 : 1

                            MouseArea {
                                id: networkMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: Networking.wifiEnabled
                                onClicked: {
                                    if (delegate.modelData.connected) {
                                        //NOTE: This turns of the wifi device...
                                        delegate.modelData.disconnect();
                                        return;
                                    }
                                    // Try to connect
                                    delegate.modelData.connect();
                                }
                            }

                            Row {
                                anchors.fill: parent
                                anchors.margins: 10
                                anchors.leftMargin: 17
                                spacing: 20

                                // security type icon (lock/unlock)
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: delegate.modelData.security !== WifiSecurityType.Open ? "\uf023" : "\uf09c"
                                    font {
                                        family: Theme.nerdFontFamily
                                        pixelSize: 12
                                    }
                                    color: "#b4b4b4"
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    Text {
                                        text: delegate.modelData.name
                                        color: "#ffffff"
                                        font {
                                            family: Theme.fontFamily
                                            pixelSize: 11
                                            weight: delegate.modelData.connected ? 500 : 300
                                        }
                                    }
                                    Text {
                                        text: delegate.modelData.connected ? "Connected" : (delegate.modelData.signalStrength >= 0 ? delegate.modelData.signalStrength + "%" : "")
                                        color: delegate.modelData.connected ? "#c8d7ef" : "#949494"
                                        elide: Text.ElideRight
                                        font {
                                            family: Theme.fontFamily
                                            pixelSize: 9
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: root.errorMessage.length > 0
                text: root.errorMessage
                color: "#e94545"
                font {
                    family: Theme.fontFamily
                    pixelSize: 11
                }
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        // password prompt overlay box
        Rectangle {
            visible: root.passwordPromptVisible
            onVisibleChanged: if (visible)
                passwordField.forceActiveFocus()
            anchors.fill: parent
            color: "#1c1c1c"
            radius: 28
            z: 10

            MouseArea {
                anchors.fill: parent
            }

            Column {
                anchors.centerIn: parent
                width: parent.width - 32
                spacing: 12

                Text {
                    width: parent.width
                    text: "Password for " + root.passwordPromptSsid
                    color: "#e1e1e1"
                    font {
                        family: Theme.fontFamily
                        pixelSize: 13
                        weight: 600
                    }
                    wrapMode: Text.Wrap
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 8
                    color: "#3a3a3a"
                    border.color: "#5a5a5a"
                    border.width: 1

                    TextInput {
                        id: passwordField
                        focus: true
                        anchors.fill: parent
                        anchors.margins: 10
                        color: "#dadada"
                        font {
                            family: Theme.fontFamily
                            pixelSize: 12
                        }
                        echoMode: TextInput.Normal
                        verticalAlignment: TextInput.AlignVCenter
                        onTextChanged: root.passwordValue = text
                        Keys.onReturnPressed: submitBtn.clicked()
                    }
                }

                Row {
                    spacing: 8
                    Rectangle {
                        id: submitBtn
                        width: 80
                        height: 32
                        radius: 9
                        color: submitBtnMA.containsMouse ? "#3065be" : "#3874d7"
                        signal clicked
                        Text {
                            anchors.centerIn: parent
                            text: "Join"
                            color: "#fff"
                            font {
                                family: Theme.fontFamily
                                pixelSize: 12
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: 80
                            }
                        }
                        MouseArea {
                            id: submitBtnMA
                            hoverEnabled: true
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                try {
                                    root.targetNetwork.connectWithPsk(root.passwordValue);
                                } catch (err) {
                                    console.log(err);
                                }
                                root.passwordPromptVisible = false;
                                root.passwordValue = "";
                                passwordField.text = "";
                                root.targetNetwork = null;
                            }
                        }
                    }

                    Rectangle {
                        width: 80
                        height: 32
                        radius: 9
                        color: cancelBtnMA.containsMouse ? "#2f2f2f" : "#343434"
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: "#dadada"
                            font {
                                family: Theme.fontFamily
                                pixelSize: 12
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: 80
                            }
                        }
                        MouseArea {
                            id: cancelBtnMA
                            hoverEnabled: true
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.passwordPromptVisible = false;
                                root.passwordValue = "";
                                passwordField.text = "";
                            }
                        }
                    }
                }
            }
        }
    }
}
