import QtQuick 1.0

Rectangle {
    id: main
    width: 500
    height: 500
    border.width: 1
    color: "white"
    Rectangle {
        id: sub
        width: 300
        height: 200
        anchors.centerIn: parent
        //anchors.bottom: main.bottom
        color: "blue"
        border.width: 1
    }
}