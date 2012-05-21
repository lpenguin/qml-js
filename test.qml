import QtQuick 1.0

Rectangle {
     id: canvas
     x:0
     y:0
     width: 400
     height: 400
     //color: "blue"
     border.width: 1
             Rectangle {
                 width: 30
                 height: 30
                 color: "black"
                 x:200
                 anchors.bottom: canvas.bottom
             }
     Rectangle {
        id: r1
        width: 100
        height: 100
        border.width: 1
        y: 50
        color: "blue"
        Rectangle {
            width: 30
            height: 30
            color: "yellow"
            anchors.bottom: r1.bottom
        }
     }
     Row {
        Rectangle {
            width: 100
            height: 100
        }
        Rectangle {
            width: 100
            height: 100
        }
        Rectangle {
            width: 100
            height: 100
        }
     }
     Rectangle {
        id: r2
         width: 100
         height: 100
         border.width: 1
         color: "green"
         //anchors.right: parent.right
         x: 100
         //anchors.top: r1.bottom
              MouseArea {
                 anchors.fill: parent
                 onClicked: {
                    r2.x+=20

                    if(parent.color == "blue")
                        parent.color = "green"
                    else
                        parent.color = "blue"

                 }
              }
     }
     Text {
        text: "hello"
        anchors.right: r1.right
        anchors.top: r1.bottom
        width: 100
     }

 }