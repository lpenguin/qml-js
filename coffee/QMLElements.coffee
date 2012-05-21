#TODO: anchors.centerIn

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
  children: null
  id: null
  type: 'Item'
  x: null
  y: null
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
    'anchors.centerIn': (v)->
      return unless v?
      @y = v.width/2
      @x = v.height/2
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
    @children = []
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
    skipnames = ['parent', 'id', 'children', 'type', 'dynamic']
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
  spacing: 0
  type: 'Row'
  width: null
  height: null

class Column extends Item
  spacing: 0
  type: 'Column'
  width: null
  height: null

class Repeater extends Item
  model: null

exportNames 'Item', 'Rectangle', 'MouseArea', 'Text', 'Row', 'Shape', 'AnchorLine', 'AnchorTypes', 'Column', 'Repeater'