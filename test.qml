Rectangle {
     id: canvas
     x:0
     y:0
     width: 400
     height: 400
     //color: "blue"
     border.width: 1
     Rectangle {
        id: r1
        width: 100
        height: 100
        border.width: 1
        y: 50
        Rectangle {
            width: 30
            height: 30
            color: "black"
            x:200
        }
     }
     Rectangle {
        id: r2
         width: 100
         height: 100
         border.width: 1
         anchors.left: r1.right
         anchors.top: r1.top
     }
 }