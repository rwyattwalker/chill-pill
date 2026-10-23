import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

Item {
    id: root
    clip: true

    property bool shown: false
    property int selectedIndex: 0
    property string searchQuery: ""
    property var appsCache: []

    signal closeRequested()

    width: 320
    height: 120
    visible: opacity > 0
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    scale: shown ? 1 : 0.96
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    property var filteredApps: searchQuery.length === 0
        ? appsCache
        : appsCache.filter(a =>
            a.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
            a.comment.toLowerCase().includes(searchQuery.toLowerCase()))

    onFilteredAppsChanged: selectedIndex = 0

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            if (root.appsCache.length === 0 || root.shown) loadApps()
        }
    }

    onShownChanged: {
        if (shown) {
            loadApps()
            resetSearch()
        }
    }

    function resetSearch() {
        searchQuery = ""
        searchInput.clear()
        selectedIndex = 0
        searchInput.focusInput()
    }

    function selectNext() {
        if (filteredApps.length === 0)
            return

        selectedIndex = (selectedIndex + 1) % filteredApps.length
        appList.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    function selectPrevious() {
        if (filteredApps.length === 0)
            return

        selectedIndex = selectedIndex <= 0 ? filteredApps.length - 1 : selectedIndex - 1
        appList.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    function loadApps() {
        let list = []
        let entries = DesktopEntries.applications.values
        for (let i = 0; i < entries.length; i++) {
            let e = entries[i]
            list.push({
                name: e.name,
                comment: e.comment || "",
                icon: e.icon,
                entry: e
            })
        }
        list.sort((a, b) => a.name.localeCompare(b.name))
        appsCache = list
    }

    function launchSelected() {
      if (filteredApps.length === 0) return
      const app = filteredApps[selectedIndex].entry
      if (app.runInTerminal) {
         if (!Config.defaultTerminal || Config.defaultTerminal.length === 0) {
             console.log("No defaultTerminal configured, cannot launch this terminal app:", app.name)
             return
         }
         Quickshell.execDetached([Config.defaultTerminal, "-e", "sh", "-c", app.command.join(" ")])
      } else {
         app.execute()
      }
      root.closeRequested()
    }

    Rectangle {
        anchors.fill: parent
        radius: 19
        color: Theme.surface
        border.color: Theme.borderSubtle
        border.width: 1
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
          width: parent.width

          Text {
              text: "Applications"
              color: Theme.fg
              font { family: Theme.fontFamily; pixelSize: 12; weight: 700 }
              Layout.leftMargin: 5
          }

          Item { Layout.fillWidth: true }

          Text {
              id: listCountText
              property int total: 0
              text: (filteredApps.count === 0 ? 0 : root.selectedIndex + 1)
                     + " / " + appList.count + " (" + appList.count + ")"
              color: "#999999"
              font { family: Theme.fontFamily; pixelSize: 9; weight: 300 }
              Layout.rightMargin: 6
            }
        }

        SearchField {
            id: searchInput
            width: parent.width
            height: 30
            radius: 8
            color: Theme.inputSurface
            placeholder: "search apps..."
            onQueryChanged: query => root.searchQuery = query
            onNextRequested: root.selectNext()
            onPreviousRequested: root.selectPrevious()
            onSubmitRequested: root.launchSelected()
            onCancelRequested: root.closeRequested()
        }

        ListView {
            id: appList
            width: parent.width
            height: parent.height - 67
            clip: true
            model: root.filteredApps
            currentIndex: root.selectedIndex
            highlightFollowsCurrentItem: false
            highlightMoveDuration: 80
            spacing: 2

            delegate: Rectangle {
                id: rowDelegate
                width: appList.width
                height: 44
                radius: 9
                color: index === root.selectedIndex
                       ? Qt.rgba(0, 0, 0, 0.20)
                       : (rowHover.hovered ? Qt.rgba(0, 0, 0, 0.20) : "transparent")
                Behavior on color { ColorAnimation { duration: 150 } }

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 7
                    width: 2
                    radius: 5
                    color: Theme.accent
                    opacity: index === root.selectedIndex ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 10
                    spacing: 10

                    IconImage {
                        id: appIcon
                        visible: Quickshell.iconPath(modelData.icon, true)
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        Layout.alignment: Qt.AlignVCenter
                        source: Quickshell.iconPath(modelData.icon, true)
                        asynchronous: true
                        scale: index === root.selectedIndex ? 1.10 : (rowHover.hovered ? 1.10 : 1)
                        Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
                    }

                    Text {
                        visible: !Quickshell.iconPath(modelData.icon, true)
                        text: "?"
                        color: Theme.fg
                        font { family: Theme.fontFamily; pixelSize: 12; weight: 700 }
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 10
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: modelData.name
                            color: Theme.fg
                            opacity: index === root.selectedIndex ? 1 : 0.9
                            font { family: Theme.fontFamily; pixelSize: 11; weight: index === root.selectedIndex ? 600 : 500 }
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: modelData.comment
                            visible: text.length > 0
                            color: "#8d8d8d"
                            font { family: Theme.fontFamily; pixelSize: 9; weight: 500 }
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                MouseArea {
                    id: rowHover
                    property bool hovered: false
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: hovered = true
                    onExited: hovered = false
                    onClicked: {
                        root.selectedIndex = index
                        root.launchSelected()
                    }
                }
              }

            Text {
                anchors.centerIn: parent
                visible: appList.count === 0
                text: "no apps found"
                color: "#666"
                font { family: Theme.fontFamily; pixelSize: 10 }
            }
        }
    }
}
