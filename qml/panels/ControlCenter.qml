pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."

Item {
    id: root
    required property var panel
    required property var shellRoot
    required property var mprisModule
    required property var notificationModule
    required property var volumeModule
    required property var brightnessModule
    required property var brightnessSetProc
    required property var brightnessThrottle
    readonly property real notificationListContentHeight: notifList.contentHeight
        anchors.centerIn: parent
        width: panel.implicitWidth - 24
        opacity: panel.controlCenter && !shellRoot.mediaAutoOpened && panel.activeOsd === "" ? 1 : 0
        visible: opacity > 0
        height: panel.controlCenter && panel.activeOsd === "" ? panel.implicitHeight - 25 : 0

        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation {
                    duration: panel.controlCenter ? 15 : 0
                }
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutExpo
                }
            }
        }

        // media player
        MediaPlayer {
            panel: root.panel
            mprisModule: root.mprisModule
            margin: 14
            artistFontSize: 10
            artistFontWeight: 300
            artistFontColor: "#7b7b7b"
            color: "#151515"
            radius: 16
            border.width: 1
        }

        // control center buttons
        CcButtons {
            buttonBorderColor: panel.ccButtonBorderColor
            buttonBorderWidth: panel.ccButtonBorderWidth
            buttonWidth: panel.ccButtonWidth
            buttonHeight: panel.ccButtonHeight
            buttonRadius: panel.ccButtonRadius
            buttonBgOff: /*panel.controlCenter && !mprisModule.hasPlayer ? "#222222" :*/ panel.ccButtonBgOff
            buttonFgOff: /*panel.controlCenter && !mprisModule.hasPlayer ? "#999999" :*/ panel.ccButtonFgOff
            controlCenterOpen: panel.controlCenter
            mediaAutoOpened: shellRoot.mediaAutoOpened
            hasPlayer: mprisModule.hasPlayer
            playerHeight: panel.ccButtonHeight
            notificationPopup: notificationModule.active
        }

        // control center sliders
        Column {
            id: sliderColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: mprisModule.hasPlayer ? panel.ccButtonHeight + 137 : 50
            anchors.leftMargin: 15
            anchors.rightMargin: 2
            spacing: 5

            // volume
            RowLayout {
                width: parent.width
                spacing: 14

                Text {
                    id: volIcon
                    text: volumeModule.icon
                    color: volumeModule.muted ? "#fd2222" : Theme.fg
                    font.family: Theme.nerdFontFamily
                    font.pixelSize: 13
                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }

                    // fade + scale pulse on every text change
                    onTextChanged: volPulse.restart()
                    scale: 1.0
                    SequentialAnimation {
                        id: volPulse
                        NumberAnimation {
                            target: volIcon
                            property: "scale"
                            to: 1.15
                            duration: 60
                        }
                        NumberAnimation {
                            target: volIcon
                            property: "scale"
                            to: 1.0
                            duration: 100
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: panel.sliderHeight
                    radius: panel.sliderRadius
                    color: "#3a3a3a"

                    Rectangle {
                        width: parent.width * (volumeModule.vol / 100)
                        height: parent.height
                        radius: panel.sliderRadius
                        color: panel.sliderColor
                        Behavior on width {
                            NumberAnimation {
                                duration: 60
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        // negative margins extend the clickable area beyond the thin bar
                        anchors.topMargin: -panel.sliderHitSlop
                        anchors.bottomMargin: -panel.sliderHitSlop
                        onClicked: mouse => {
                            volumeModule.sink.audio.volume = Math.max(0, Math.min(1, mouse.x / width));
                        }
                        onPositionChanged: mouse => {
                            if (pressed)
                                volumeModule.sink.audio.volume = Math.max(0, Math.min(1, mouse.x / width));
                        }
                    }
                }

                Text {
                    text: volumeModule.muted ? "muted" : volumeModule.vol + "%"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    Layout.minimumWidth: 35
                }
            }

            // brightness
            RowLayout {
                width: parent.width
                spacing: 14

                Text {
                    id: blIcon
                    text: brightnessModule.icon
                    color: Theme.fg
                    font.family: Theme.nerdFontFamily
                    font.pixelSize: 13

                    // fade+scale pulse on every text change
                    onTextChanged: blPulse.restart()
                    scale: 1.0
                    SequentialAnimation {
                        id: blPulse
                        NumberAnimation {
                            target: blIcon
                            property: "scale"
                            to: 1.15
                            duration: 60
                        }
                        NumberAnimation {
                            target: blIcon
                            property: "scale"
                            to: 1.0
                            duration: 100
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: panel.sliderHeight
                    radius: panel.sliderRadius
                    color: "#3a3a3a"

                    Rectangle {
                        width: parent.width * brightnessModule.percent
                        height: parent.height
                        radius: panel.sliderRadius
                        color: panel.sliderColor
                        Behavior on width {
                            NumberAnimation {
                                duration: 60
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        // negative margins extend the clickable area beyond the thin bar
                        anchors.topMargin: -panel.sliderHitSlop
                        anchors.bottomMargin: -panel.sliderHitSlop
                        onClicked: mouse => {
                            let pct = Math.round(Math.max(0, Math.min(1, mouse.x / width)) * 100);
                            brightnessSetProc.command = ["brightnessctl", "set", pct + "%"];
                            brightnessSetProc.running = false;
                            brightnessSetProc.running = true;
                        }
                        onPositionChanged: mouse => {
                            if (pressed && !brightnessThrottle.running) {
                                let pct = Math.round(Math.max(0, Math.min(1, mouse.x / width)) * 100);
                                brightnessSetProc.command = ["brightnessctl", "set", pct + "%"];
                                brightnessSetProc.running = false;
                                brightnessSetProc.running = true;
                                brightnessThrottle.start();
                            }
                        }
                    }
                }

                Text {
                    text: Math.round(brightnessModule.percent * 100) + "%"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    Layout.minimumWidth: 35
                }
            }
        }

        // notifications stack popped header
        Rectangle {
            id: headerBar
            anchors.top: notifBox.top
            anchors.topMargin: -21
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 10
            height: 35
            topLeftRadius: 13
            topRightRadius: 13
            bottomLeftRadius: 0
            bottomRightRadius: 0
            color: "#2f2f2f"
            visible: notifBox.visible
            z: 0

            Item {
                Layout.fillWidth: true
                height: 16

                Text {
                    text: "Notifications (" + notificationModule.notifications.length + ")"
                    color: "#dddddd"
                    font {
                        family: Theme.fontFamily
                        pixelSize: 9
                        weight: 400
                    }
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.topMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 60
                    height: 16
                    radius: 10
                    color: clearAllHover.containsMouse ? "#1d1d1d" : "#242424"
                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 3
                    anchors.rightMargin: -345

                    Text {
                        text: "Clear all"
                        color: "#dedede"
                        font {
                            family: Theme.fontFamily
                            pixelSize: 8
                            weight: 300
                        }
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: clearAllHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: notificationModule.clearAll()
                    }
                }
            }
        }

        // notifications list stack
        Rectangle {
            id: notifBox
            anchors.top: sliderColumn.bottom
            anchors.topMargin: 32
            anchors.bottomMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 10
            height: Math.min(notifList.contentHeight + 7, shellRoot.notifMaxHeight)
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: 13
            bottomRightRadius: 13
            color: "#161616"
            visible: notificationModule.notifications.length > 0 && panel.controlCenter
            clip: true
            border.width: 1
            border.color: "#2f2f2f"
            z: 1

            Behavior on height {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutQuad
                }
            }

            ListView {
                id: notifList
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 5
                anchors.leftMargin: 5
                anchors.rightMargin: 5
                height: Math.min(contentHeight, shellRoot.notifMaxHeight)
                spacing: 6
                model: notificationModule.notificationsReversed
                clip: true
                interactive: contentHeight > height
                flickDeceleration: 3000
                maximumFlickVelocity: 2500
                boundsBehavior: Flickable.StopAtBounds

                // cache delegates instead of recreating on scroll
                cacheBuffer: 200
                reuseItems: true

                ScrollBar.vertical: ScrollBar {
                    id: notifScrollBar
                    policy: ScrollBar.AlwaysOff
                    visible: notifList.contentHeight > notifList.height
                    width: 10
                    anchors.rightMargin: 10
                    z: 20
                    contentItem: Rectangle {
                        implicitWidth: 8
                        radius: 10
                        color: notifScrollBar.pressed ? "#888" : scrollHover.hovered ? "#6f6f6f" : "#3a3a3a"
                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }
                        HoverHandler {
                            id: scrollHover
                        }
                    }
                }

                // add/append notifications in the stack
                delegate: Item {
                    id: notifDelegate
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: contentColumn.implicitHeight + 7

                    // glyph (nerd font) bell icon
                    Text {
                        id: bellIcon
                        text: String.fromCodePoint(0xf0f3)
                        color: Theme.fg
                        font {
                            family: Theme.nerdFontFamily
                            pixelSize: 16
                        }
                        visible: notifIcon.status !== Image.Ready
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        anchors.leftMargin: 16
                    }

                    // custom appicon
                    Image {
                        id: notifIcon
                        width: 22
                        height: 22
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        source: {
                            if (notifDelegate.modelData.image)
                                return notifDelegate.modelData.image;
                            if (notifDelegate.modelData.appIcon) {
                                return notifDelegate.modelData.appIcon.startsWith("/") ? "file://" + notifDelegate.modelData.appIcon : "image://icon/" + notifDelegate.modelData.appIcon;
                            }
                            return "";
                        }
                        sourceSize: Qt.size(22, 22)
                        visible: status === Image.Ready
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.topMargin: 10
                        anchors.leftMargin: 15
                    }

                    ColumnLayout {
                        id: contentColumn
                        anchors.fill: parent
                        anchors.leftMargin: 50
                        anchors.rightMargin: 3
                        anchors.bottomMargin: 20
                        spacing: 1

                        Item {
                            Layout.fillHeight: true
                            Layout.topMargin: 8
                            visible: !bodyText.visible
                        }

                        // heading / summary
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: notifDelegate.modelData.summary
                                color: Theme.fg
                                font {
                                    family: Theme.fontFamily
                                    pixelSize: 11
                                    weight: 600
                                }
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: notifDelegate.modelData.receivedTime ? Qt.formatTime(notifDelegate.modelData.receivedTime, "hh:mm") : ""
                                color: "#858585"
                                font {
                                    family: Theme.fontFamily
                                    pixelSize: 8
                                }
                                Layout.bottomMargin: 5
                            }

                            // close button
                            Rectangle {
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                radius: 99
                                color: dismissHover.containsMouse ? "#333333" : "transparent"
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 100
                                    }
                                }

                                Text {
                                    text: ""
                                    color: dismissHover.containsMouse ? "#bebebe" : "#404040"
                                    anchors.centerIn: parent
                                    font.pixelSize: 11
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }

                                MouseArea {
                                    id: dismissHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: notificationModule.dismiss(notifDelegate.modelData._id)
                                }
                            }
                        }

                        // description / body
                        Text {
                            id: bodyText
                            text: notifDelegate.modelData.body
                            color: "#9f9f9f"
                            font {
                                family: Theme.fontFamily
                                pixelSize: 9
                                weight: 300
                            }
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            Layout.bottomMargin: 2
                            visible: text !== ""
                        }

                        Item {
                            Layout.fillHeight: true
                            Layout.bottomMargin: 6
                            visible: !bodyText.visible
                        }
                    }

                    // divider
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: "#333"
                        visible: notifDelegate.index < notificationModule.notifications.length - 1
                    }
                }
            }
        }
}
