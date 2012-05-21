#TODO: x,y position not changes if anchors.*
#TODO: move global elcount in class QMLParser
elcount=0
class QMLParser
  elcount: 0
  replaces: [
    #  re: /\;/g
    #  repl: "\n"
    #,
      re: /on(\w+)\s*:\s*\{/ #event handler (multiline)
      repl: 'on$1: function(){'
      do: ()-> @inevent = true
    ,
      re: /on(\w+)\s*:\s*(\w[^\{]+)/ #event handler (oneline)
      repl: "on$1: function()\{$2\}"
    ,
      re:  /(\w+)\s*{/g #item declaration
      repl:  (tmpl, found) -> 'elem'+(elcount++)+': { "type": "'+found+'",'
    #,
     # re: /(})/ #close bracket
    #  repl: '$1,'
      #do: ()->@closedbr++
    #,
    #  re: /({})/ #close bracket
    #  do: ()->@openedbr++
    ,
      re: /([\w\.]+)\:\s*(\d+)$/ #number property (width: 100)
      repl: '"$1": $2,'
    ,
      re: /([\w\.]+)\s*\:\s*\"([^\"]+)"/ #string property eg. text: "hello"
      repl:'\"$1\": \"\\\"$2\\\"\",'
      #repl:'$1 $2 '
    ,
      re: /([\w\.]+)\s*\:\s*([^\"\']+)$/ #ref properties ( anchors.fill: parent)
      repl: '"$1": "$2",'
    ,
      re: /([\w\.]+)\s*\:\s*\'([^\']+)'/ #string property eg. text: 'hello'
      repl: '\"$1\": \"\\\"$2\\\"\",'
    ,


      re: /import QtQuick [\d\.]+/ #imports eg. import QtQuick 1.0
      repl: ''
    #,
    #  re: /,$/ #end of line
    #  repl: ''
  ]

  parseQML: (qmlstr) ->
    @elcount = 0
    qmlstr=qmlstr.replace /\}([\s\n]*)(\w+)[\s\n]*\{/g, '},$1 $2 {'
    lines = qmlstr.split /[\n\;]/
    strs = []

    for line in lines
      replaced = false
      for replace in @replaces
        if line.match(replace.re)
          strs.push line.replace( replace.re, replace.repl )
          replaced = true
          break
      if not replaced
        strs.push  line

    str = strs.join('\n').replace( /,$/, '' )
    console.log str
    obj = eval "({"+str+"})"
    return obj['elem0']

  parse: (str)->
    return @parseQML str



class QMLEngine
  items: {}
  count: 0
  evaluate: (str, context)->
    `with(context){
      r=eval(str);
    }`
    return r
  depencities: {}

  exportAll: ()->
    for name, item of @items
      Root[name] = item
  export: (item)->
    Root[item.id] = item

  defineDependency: (id, key, depid, depkey)->

    obj = @findItem id
    if depid == 'this'
      depid = id
    if depid == 'parent'
      depid = obj.parent.id
    if depkey == 'this'
      depkey = '*'
    dependencyName = depid+'/'+depkey
    #console.log "depname: #{dependencyName}"
    @depencities[depid] = {} if not @depencities[depid]?
    @depencities[depid][depkey] = [] if not @depencities[depid][depkey]?
    @depencities[depid][depkey].push obj: obj, key: key

  getDepencities: (id, prop)->
    dep = @depencities[id]
    return null unless dep
    res = []
    if dep['*']
      for d in dep['*']
        res.push d
    if dep[prop]
      for d in dep[prop]
        res.push d
    return null unless res.length
    return res
  updateDepencities: (id, key, newvalue)->
    qmlView.updateDepencities(id, key, newvalue)
    deps = @getDepencities(id, key)
    return if not deps

    for dep in deps
      console.log "updating #{dep.obj.id} #{dep.key} "
      dep.obj[dep.key] = dep.obj[dep.key]

  getNewId: ()->
    return 'obj'+@count++

  findItem: (id)->
    return @items[id]
  registerItem: (obj)->
    @items[obj.id] = obj
  createObjects: (obj, parent) ->
    parent = null if not parent?
    res = null
    switch obj.type
      when "Rectangle" then res =  new Rectangle parent, obj
      when "Text" then res = new Text parent, obj
      when "MouseArea" then res = new MouseArea parent, obj
      when "Row" then res = new Row parent, obj
    re = /elem\d+/
    return unless res?

    for own key, child of obj
      continue unless typeof key == 'string'
      if re.test key
        res.childs.push @createObjects child, res
    return res

class QMLView
  domlinks: null
  constructor: ()->
    @domlinks = {}
  createElement: (el, parent)->
    childs = []
    for child in el.childs
      childs.push @createElement child, res

    res = null
    switch el.type
      when 'Rectangle' then res = @createRectangle el, parent, childs
      when 'Text' then res = @createText el, parent, childs
      when 'MouseArea' then res = @createMouseArea el, parent, childs
      when 'Row' then res = @createRow el, parent, childs
    return null if not res?

    res.attr id: "qml-#{el.id}"
    @domlinks[el.id] = res

    for prop in el.getProperties()
      @setDomProperty(res, prop, el)

    return res
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

  createRectangle: (el, parent, childs)->
    domobj = atom.dom.create('div')#.appendTo( parent );
    domobj.addClass 'Rectangle'
    for child in childs
      child.appendTo domobj
    return domobj
  createText: (el, parent, childs)->
    #domobj = parent.create 'div'
    domobj = atom.dom.create('span')#.appendTo( parent );
    domobj.addClass 'Text'
    for child in childs
      child.appendTo domobj
    return domobj
  createMouseArea: (el, parent, childs)->
    #domobj = parent.create 'div'
    domobj = atom.dom.create('div')#.appendTo( parent );
    domobj.addClass 'MouseArea'
    domobj.bind click: (e)->
      el.onClicked()
      return false
    for child in childs
      child.appendTo domobj
    return domobj

  createRow: (el, parent, childs)->
    domobj = atom.dom.create('table')#.appendTo( parent );
    #
    domobj.addClass 'Row'
    tr = atom.dom.create 'tr'
    tr.appendTo domobj
    for child in childs
      td = atom.dom.create 'td'
      td.appendTo tr
      child.appendTo td
      child.css position: 'static'
    return domobj
  #getCSSMetric: (domobj, cssname)->
  #  value = domobj.first[ cssname ]
  #  return value #parseInt value.replace('px', '')
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
    width:              (domobj, v)-> domobj.css width: v
    height:             (domobj, v)-> domobj.css height: v
    x:                  (domobj, v, el)-> domobj.css left: v if not el['anchor.left'] and not el['anchor.right']
    y:                  (domobj, v, el)-> domobj.css top: v if not el['anchor.top'] and not el['anchor.bottom']
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
#    'anchors.fill': (domobj, v, el)->
#      #TODO: can siblings fill
#      throw Error "Cannot anchor to an item that isn't a parent or sibling" unless el.parent == v or el.parent == v.parent
#      #m = qmlView.getCSSMetrics qmlView.domlinks[v.id]
#      domobj.css
#        width: v.width+'px'
#        height: v.height+'px'
#      return domobj
#    'anchors.right': (domobj, v, el)->
#      throw Error "Cannot anchor to an item that isn't a parent or sibling"  unless v.isValid el
#      pos = v.value()
#      domobj.css left: (pos-el.width)+'px'#(pm.width - m.width )+'px'
#    'anchors.left': (domobj, v, el)->
#      throw Error "Cannot anchor to an item that isn't a parent or sibling"  unless v.isValid el
#      pos = v.value()
#      domobj.css left: (pos)+'px'#(pm.width - m.width )+'px'
#    'anchors.top': (domobj, v, el)->
#      throw Error "Cannot anchor to an item that isn't a parent or sibling"  unless v.isValid el
#      pos = v.value()
#      domobj.css top: (pos)+'px'#(pm.width - m.width )+'px'
#    'anchors.bottom': (domobj, v, el)->
#      throw Error "Cannot anchor to an item that isn't a parent or sibling"  unless v.isValid el
#      pos = v.value()
#      domobj.css top: (pos-el.height)+'px'#(pm.width - m.width )+'px'

qmlEngine = new QMLEngine()
qmlView = new QMLView()
qmlParser  = new QMLParser()

exportNames = (names...) ->
  for cl in names
    Root[cl] = eval '('+cl+')'
  return null


AnchorTypes =
  left: 0
  right: 1
  top: 2
  bottom: 3

class AnchorLine
  type: AnchorTypes.left
  item: null
  constructor: (type, item)->
    @type = type
    @item = item
  value: (anchoreditem)->
    switch @type
      when AnchorTypes.left
        if @item.isParent anchoreditem
          return 0
        if @item.isSibling anchoreditem
          return @item.x
        throw Error "Cannot anchor to an item that isn't a parent or sibling"
      when AnchorTypes.right
        if @item.isParent anchoreditem
          return @item.width
        if @item.isSibling anchoreditem
          return @item.x + @item.width
        throw Error "Cannot anchor to an item that isn't a parent or sibling"

      when AnchorTypes.top
        if @item.isParent anchoreditem
          return 0
        if @item.isSibling anchoreditem
          return  @item.height
        throw Error "Cannot anchor to an item that isn't a parent or sibling"

      when AnchorTypes.bottom
        if @item.isParent anchoreditem
          return @item.height
        if @item.isSibling anchoreditem
          return @item.y + @item.height
        throw Error "Cannot anchor to an item that isn't a parent or sibling"

     throw Error "Undefined anchor type"
  isValid: (item)->
    return ( item.parent == @item or
       item.parent == @item.parent )

class Item
  parent: null
  childs: null
  id: null
  type: 'Item'
  x: 0
  y: 0
  width: 0
  height: 0
  color: "''"
  'anchors.centerIn': null
  'anchors.fill': null
  'anchors.left': null
  'anchors.right': null
  'anchors.top': null
  'anchors.bottom': null
  'border.color': '"black"'
  'border.width': 0

  anchors:
    'anchors.left': (v)->
      return unless v?
      @x = v.value(this)
    'anchors.right': (v)->
      return unless v?
      @x = v.value(this) - @width
    'anchors.top': (v)->
      return unless v?
      @y = v.value(this)
    'anchors.bottom': (v)->
      return unless v?
      @y = v.value(this) - @height
    'anchors.fill': (v)->
      return unless v?
      @y = 0
      @x = 0
      @width = v.width
      @height = v.height
  dynamic:
    'left':
      get: ()->
        return new AnchorLine AnchorTypes.left, this
    'right':
      get: ()->
        new AnchorLine AnchorTypes.right, this
      deps: ['width']
    'top':
      get: ()->
        new AnchorLine AnchorTypes.top, this
    'bottom':
      get: ()->
        new AnchorLine AnchorTypes.bottom, this
      deps: ['height']

  isSibling: (item)->
    return @parent == item.parent
  isParent: (item)->
    return this == item.parent
  appendSetter: (prop, setter)->
    oldsetter = this.__lookupSetter__ prop
    this.__defineSetter__ prop, (v)->
      setter.call this, v
      oldsetter.call this, v
  ready: () ->
    console.log "#{@id} ready"
    return null
  defineGetter: (propName) ->
    @.__defineGetter__ propName, ()->
      #trace = printStackTrace()
      #console.log '>>>>getter<<<<'
      #console.log trace.join '\n'
      #if typeof this["_"+propName] == 'string'
      return qmlEngine.evaluate this["_"+propName], this
      #else
      #  return this["_"+propName]
  defineSetter: (propName) ->
    @__defineSetter__ propName, (value)->
      if typeof value == "string"
        value = "\"#{value}\""
      this['_'+propName] = value
      qmlEngine.updateDepencities(@id, propName, value)

  readOptions: (options) ->
    for prop in @getPropertiesPublic(true)
      this['_'+prop] = this[prop]
      continue unless options[prop]?
      #if typeof options[prop] == 'function'
      #  options[prop] = '__f__'+options[prop].toString().replace(/function\s*\(\s*\)\s*\{/, '').replace(/\}$/, '')
      this['_'+prop] = options[prop]

  constructor: (parent, options) ->
    @childs = []
    if not options?
      @parent = null
      options = parent
    else
      if typeof(parent) == 'object'
        @parent = parent
      else
        @parent = qmlEngine.findItem parent
    @id = options.id or qmlEngine.getNewId()
    qmlEngine.registerItem(this)
    qmlEngine.export(this)
    @defineDynamicProperties()
    @readOptions(options)

    console.log 'created: '+@type
    console.log ' with id: '+@id
    console.log ' with parent: '+@parent.id if @parent
    @defineGettersSetters()
    for prop, setter of @anchors
      @appendSetter prop, setter
      this[prop] = this[prop]
    @ready()

  defineDynamicSetter: (thisid, propname)->
    @__defineSetter__ propname, (v)->
      qmlEngine.updateDepencities(@id, propname, v)
      #set.call(this, v)
  defineDynamicProperties: ()->
    for own propname, prop of @dynamic
      @__defineGetter__ propname, prop.get if prop.get
      @defineDynamicSetter @id, propname #if prop.set
      if prop.deps
        for dep in prop.deps
          qmlEngine.defineDependency(@id, propname, @id, dep)

    return undefined

  getProperties: (getnullprops=false)->
    res = []
    skipnames = ['_parent', '_id', '_childs', '_type', '_dynamic']
    for key, value of this
      continue if not key.match(/^_/) or key in skipnames
      continue if not value? && not getnullprops
      res.push key.replace /^_/,''
    return res
  getPropertiesPublic: (getnullprops=false)->
    res = []
    skipnames = ['parent', 'id', 'childs', 'type', 'dynamic']
    for key, value of this
      continue if key.match(/^_/ )or key in skipnames
      continue if not value? && not getnullprops
      res.push key.replace /^_/,''
    return res

  getPropertiesObj: (getnullprops=false)->
    res = {}
    skipnames = ['_parent', '_id', '_childs', '_type', '_dynamic']
    for key, value of this
      continue if not key.match(/^_/) or key in skipnames
      continue if not value? && not getnullprops
      res[key.replace /^_/,''] = value
    return res

  defineGettersSetters: ()->
    for key, value of @getPropertiesObj(true)
      continue if @dynamic[key]?
      if value?
        this['_'+key] = value
        unless typeof value == 'string'
          for dep in @getDependencyNames(value)
            qmlEngine.defineDependency(@id, key, dep.id, dep.key)
        #else
        #  this['_'+key] = '"'+(value.replace /^__f__/, '').replace( /\"/g ,"\\\"").replace(/\n/g, "\"+\n+\"")+'"'
      @defineGetter key
      @defineSetter key
    return null

  getDependencyNames: (nameStr)->
    strre = new RegExp '^(\"|\').*(\"|\')$'
    digre = new RegExp '^[0-9.]+$'
     #'^[\d\.]+$'

    return [] if typeof nameStr != 'string'
    nameStr.replace(/^\s\s*/, '').replace(/\s\s*$/, '')
    return [] if strre.test(nameStr) or digre.test(nameStr)
    namere = /\w+[\w\.]*\w*/g
    m = nameStr.match(namere)
    return [] if not m
    res = []
    for name in m
      continue if digre.test name
      if name == 'parent'
        res.push id: 'parent', key: 'this'
        continue
      r=name.split('.')
      if r.length == 1
        id = 'this'
        key = name
      else
        id = r.shift()
        key = r.join('.')
      res.push id: id, key: key
    return res

class Shape extends Item
  #color: null
  type: 'Shape'

class Text extends Shape
  text: '""'
  type: 'Text'

class Circle extends Shape
  radius: 0
  type: 'Circle'

class Rectangle extends Shape
  radius: null
  type: 'Rectangle'

class MouseArea extends Item
  ready: ()->
    s = this.onClicked.toString()
                          #.replace(/\"/g,"\\\"")
                          .replace(/function\s*\(\s*\)\s*\{/, 'function(){with(this){')+"}"
    this['_onClicked'] = eval "("+s+")"

    super()
  onClicked: null
  type: 'MouseArea'
  prop: ''

class Row extends Item
  type: 'Row'
  width: null
  height: null
#item = qmlEngine.parseQML str
#canvas = qmlEngine.findItem('canvas')

#if window?
#  atom.dom ()->
Root = window
window.Root = Root
exportNames 'Item', 'Shape', 'Text', 'Rectangle', 'Circle', 'QMLEngine', 'qmlView', 'qmlEngine', 'qmlParser'
#console.log convertQML str