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
            color: "black"
            anchors.bottom: canvas.bottom
        }
     }
     Rectangle {
        id: r2
         width: 100
         height: 100
         border.width: 1
         color: "green"
         anchors.right: parent.right
         anchors.top: r1.bottom
     }
     Text {
        text: "hello"
        anchors.right: r1.right
        anchors.top: r1.bottom
     }
 }