import QtQuick

Rectangle {
    id: root

    property string placeholder: "Search..."
    property color textColor: Theme.fg
    property color placeholderColor: Theme.textMuted
    property color normalBorderColor: Theme.borderSubtle
    property color focusedBorderColor: "#666"
    property int textPixelSize: 11
    property int horizontalPadding: 10
    property bool handleDelete: false

    signal nextRequested()
    signal previousRequested()
    signal submitRequested()
    signal cancelRequested()
    signal deleteRequested()
    signal queryChanged(string query)

    function focusInput() {
        textInput.forceActiveFocus();
    }

    function clear() {
        textInput.clear();
    }

    color: Theme.inputSurface
    border.color: textInput.activeFocus ? focusedBorderColor : normalBorderColor
    border.width: 1

    Behavior on border.color {
        ColorAnimation { duration: 120 }
    }

    TextInput {
        id: textInput
        anchors.fill: parent
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
        verticalAlignment: TextInput.AlignVCenter
        color: root.textColor
        font.family: Theme.fontFamily
        font.pixelSize: root.textPixelSize
        clip: true
        onTextChanged: root.queryChanged(text)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            color: root.placeholderColor
            font: textInput.font
            visible: textInput.text.length === 0
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Down)
                root.nextRequested();
            else if (event.key === Qt.Key_Up)
                root.previousRequested();
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                root.submitRequested();
            else if (event.key === Qt.Key_Escape)
                root.cancelRequested();
            else if (event.key === Qt.Key_Delete) {
                if (!root.handleDelete)
                    return;
                root.deleteRequested();
            }
            else
                return;

            event.accepted = true;
        }
    }
}
