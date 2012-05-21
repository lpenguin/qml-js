atom.dom () ->
  root  = atom.dom('div').first
   #qmlView.domroot = atom.dom  root
  atom.dom('#incwidth').bind 'click': ()->
    canvas.width+=100
  atom.dom('#incheight').bind 'click': ()->
    canvas.height+=100
   atom.dom('#incx').bind 'click': ()->
    canvas.x+=100
  atom.dom('#incy').bind 'click': ()->
    canvas.y+=100
  atom.dom('script[type="text/qml"]').each (el)->
    atom.ajax
      url: el.src
      type: 'plain'
      method: 'get'
      onLoad: (data)->
        data = qmlParser.parse(data)
        rootElem = qmlEngine.createObjects(data)
        qmlEngine.exportAll()
        r = qmlView.createElement rootElem, root
        r.appendTo root



