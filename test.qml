import QtQuick 1.0

Rectangle {
     id: canvas
     x:0
     y:0
     width: 400
     height: 400
     color: "blue"
     states: [
         State {
             name: "CRITICAL"
             PropertyChanges {
                    target: canvas
                    color: "red"
             }
         }
     ]
     MouseArea {
         anchors.fill: canvas
         onClicked: {
            console.log('clicked');
             if (canvas.state == "")
                 canvas.state = "CRITICAL"
             else
                 canvas.state = ""
         }
     }
 }