exportNames = (names...) ->
  for cl in names
    Root[cl] = eval '('+cl+')'
  return null


class QMLView
  domlinks: null
  constructor: ()->
    @domlinks = {}
  createElement: (el, parent)->
    dom = null
    switch el.type
      when 'Rectangle' then dom = @createRectangle el, parent
      when 'Text' then dom = @createText el, parent
      when 'MouseArea' then dom = @createMouseArea el, parent
      when 'Row' then dom = @createRow el, parent
      when 'Column' then dom = @createColumn el, parent
      when 'Repeater' then dom = @createRepeater el, parent
    return null if not dom

    dom.attr id: "qml-#{el.id}"
    @domlinks[el.id] = dom

    for prop in el.getProperties()
      @setDomProperty(dom, prop, el)

    children = []
    for child in el.children
      children.push @createElement child, dom

    for child in children
      child.appendTo dom
          
    return dom
  appendChildrenToRow: (row, children)->
    tr = atom.dom.create 'tr'
    tr.appendTo row
    for child in children
      td = atom.dom.create 'td'
      td.appendTo tr
      child.appendTo td
      #child.css position: 'static'

  appendChildrenToColumn: (column, children)->

    #  tr = atom.dom.create 'tr'
     # tr.appendTo column
     # td = atom.dom.create 'td'
    #  td.appendTo tr
    for child in children
      child.appendTo column
      #child.css position: 'static'

  updateDepencities: (id, property, newvalue)->
    el = qmlEngine.findItem(id)
    domobj = @domlinks[id]
    return unless domobj
    @setDomProperty(domobj, property, el)

  setDomProperty: (domobj, property, el)->
    f = @propFunctions[property]
    return if not f
    value = el[property]
    f(domobj, value, el)

  createRectangle: (el, parent)->
    domobj = atom.dom.create('div')#.appendTo( parent );
    domobj.addClass 'Rectangle'
    return domobj

  createRepeater: (el, parent)->
    domobj = atom.dom.create('div')#.appendTo( parent );
    domobj.addClass 'Repeater'
    return domobj

  createText: (el, parent)->
    domobj = atom.dom.create('span')#.appendTo( parent );
    domobj.addClass 'Text'
    return domobj
  createMouseArea: (el, parent)->
    domobj = atom.dom.create('div')#.appendTo( parent );
    domobj.addClass 'MouseArea'
    domobj.bind click: (e)->
      el.onClicked()
      return false
    return domobj
  createRow: (el, parent)->
    domobj = atom.dom.create('table')#.appendTo( parent );
    domobj.addClass 'Row'
    return domobj
  createColumn: (el, parent)->
    domobj = atom.dom.create('table')#.appendTo( parent );
    domobj.addClass 'Column'
    return domobj
  createRepeater: (el, parent)->
    domobj = atom.dom.create('div')#.appendTo( parent );
    domobj.addClass 'Repeater'

  getCSSMetrics: (domobj)->
    #cssnames = ['width', 'height', 'left', 'top']
    domobj = domobj.first
    w = domobj.offsetWidth
    h = domobj.offsetHeight
    metric =
      width: w
      height: h
      left: domobj.offsetLeft
      top: domobj.offsetTop
      right: domobj.offsetLeft + w
      bottom: domobj.offsetTop + h
    return metric
  propFunctions:
    width:              (domobj, v)-> domobj.css width: v+'px'
    height:             (domobj, v)-> domobj.css height: v+'px'
    x:                  (domobj, v, el)-> domobj.css left: v #if not el['anchors.left'] and not el['anchors.right']
    y:                  (domobj, v, el)-> domobj.css top: v #if not el['anchors.top'] and not el['anchors.bottom']
    color:              (domobj, v, el)->
      if el.type == 'Text'
        domobj.css 'color': v
      else
        domobj.css 'background-color': v
    text:               (domobj, v)-> domobj.html v
    'border.width':     (domobj, v)-> domobj.css 'border-width': v+'px', 'border-style': 'solid'
    'border.color':     (domobj, v)-> domobj.css 'border-color': v
    'anchors.centerIn': (domobj, v, el)->
      return unless el.parent
      m = qmlView.getCSSMetrics domobj
      parentm = qmlView.getCSSMetrics qmlView.domlinks[el.parent.id]
      domobj.css
        left: ( parentm.width/ 2 - m.width/ 2)+"px"
        top: (parentm.height/2 - m.height/2)+"px"
      return domobj
    spacing: (domobj, v, el)->
      domobj.css
        'border-spacing': v+'px'
        'margin-left':'-'+v+'px'

qmlView = new QMLView()

exportNames 'qmlView'