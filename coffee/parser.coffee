class QMLEngine
  items: {}
  count: 0
  evaluate: (str, context)->
    `with(context){
      r=eval(str)
    }
    `
    return r
  depencities: {}
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

  readQML: (qmlstr) ->
    elcount = 0
    openStructRe = /(\w+)\s*{/g
    openStructReplace = (tmpl, found) -> 'elem'+(elcount++)+': { "type": "'+found+'",'

    closeStructRe = /(})/g
    closeStructReplace = '$1,'

    propStuctRe = /([\w\.]+)\:\s*([^\"\'\n]+)\n/g
    propStuctReplace = '"$1": "$2",\n'

    propStuctDRe = /([\w\.]+)\:\s*(\d+)/g
    propStuctDReplace = '"$1": $2,'

    propStuctSRe = /([\w\.]+)\:\s*\"([^\"]+)\"/g
    propStuctSReplace = '\"$1\": \"\\\"$2\\\"\",'

    propStuctSRe2 = /([\w\.]+)\:\s*\'([^\']+)\'/g
    propStuctSReplace2 = '\"$1\": \"\\\"$2\\\"\",'

    qmlstr= qmlstr.replace openStructRe, openStructReplace
    qmlstr = qmlstr.replace closeStructRe, closeStructReplace
    qmlstr = qmlstr.replace propStuctRe,   propStuctReplace
    qmlstr = qmlstr.replace propStuctSRe,  propStuctSReplace
    qmlstr = qmlstr.replace propStuctSRe2,  propStuctSReplace2


    qmlstr = qmlstr.replace(/,$/,'')
    obj = eval "({"+qmlstr+"})"
    return obj['elem0']
  parseQML: (obj, parent) ->
    if typeof obj == 'string'
      obj = @readQML obj
    parent = null if not parent?

    res = null
    switch obj.type
      when "Rectangle" then res =  new Rectangle parent, obj
      when "Text" then res = new Text parent, obj
    re = /elem\d+/
    return unless res?

    for own key, child of obj
      continue unless typeof key == 'string'
      if re.test key
        res.childs.push @parseQML child, res
    return res
  exportAll: ()->
    for name, item of @items
      Root[name] = item

class QMLView
  domlinks: null
  constructor: ()->
    @domlinks = {}
  createElement: (el, parent)->
    res = null
    switch el.type
      when 'Rectangle' then res = @createRectangle el, parent
      when 'Text' then res = @createText el, parent
    return null if not res?

    res.attr id: "qml-#{el.id}"
    @domlinks[el.id] = res

    for prop in el.getProperties()
      @setDomProperty(res, prop, el)
    for child in el.childs
      subelement = @createElement child, res
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

  createRectangle: (el, parent)->
    #domobj = parent.create 'div'
    domobj = atom.dom.create('div').appendTo( parent );
    domobj.addClass 'Rectangle'
    return domobj
  createText: (el, parent)->
    #domobj = parent.create 'div'
    domobj = atom.dom.create('span').appendTo( parent );
    domobj.addClass 'Text'
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
    'anchors.fill': (domobj, v, el)->
      m = qmlView.getCSSMetrics qmlView.domlinks[v.id]
      domobj.css
        width: m.width+'px'
        height: m.height+'px'
      return domobj
    'anchors.right': (domobj, v, el)->
      pos = v.value()
      domobj.css left: (pos-el.width)+'px'#(pm.width - m.width )+'px'
    'anchors.left': (domobj, v, el)->
      pos = v.value()
      domobj.css left: (pos)+'px'#(pm.width - m.width )+'px'
    'anchors.top': (domobj, v, el)->
      pos = v.value()
      domobj.css top: (pos)+'px'#(pm.width - m.width )+'px'
    'anchors.bottom': (domobj, v, el)->
      pos = v.value()
      domobj.css top: (pos-el.height)+'px'#(pm.width - m.width )+'px'

qmlEngine = new QMLEngine()
qmlView = new QMLView()


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
  value: ()->
    switch @type
      when AnchorTypes.left then return @item.x
      when AnchorTypes.right then return @item.x+@item.width
      when AnchorTypes.top then return @item.y
      when AnchorTypes.bottom then return @item.y+@item.height
    return null

class Item
  parent: null
  childs: null
  id: null
  type: 'Item'
  x: null
  y: null
  width: 0
  height: 0
  'anchors.centerIn': null
  'anchors.fill': null
  'anchors.left': null
  'anchors.right': null
  'anchors.top': null
  'anchors.bottom': null
  'border.color': '"black"'
  'border.width': 0

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



  defineGetter: (propName) ->
    @.__defineGetter__ propName, ()-> qmlEngine.evaluate this["_"+propName], this

  defineSetter: (propName) ->
    @__defineSetter__ propName, (value)->
      this['_'+propName] = value
      qmlEngine.updateDepencities(@id, propName, value)

  readOptions: (options) ->
    for prop in @getProperties(true)
      continue unless options[prop]?
      this[prop] = options[prop]

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

    @defineDynamicProperties()
    @readOptions(options)

    console.log 'created: '+@type
    console.log ' with id: '+@id
    console.log ' with parent: '+@parent.id if @parent
    @defineGettersSetters()

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
    skipnames = ['parent', 'id', 'childs', 'type', 'dynamic']
    for key, value of this
      if key in skipnames or typeof this[key] == 'function' or key.match /^_/
        continue
      if not value? && not getnullprops
        continue
      res.push key
    return res

  getPropertiesObj: (getnullprops=false)->
    res = {}
    skipnames = ['parent', 'id', 'childs', 'type', 'dynamic']
    for key, value of this
      if key in skipnames or typeof this[key] == 'function' or key.match /^_/
        continue
      if not value? && not getnullprops
        continue
      res[key] = value
    return res

  defineGettersSetters: ()->
    for key, value of @getPropertiesObj(true)
      continue if @dynamic[key]?
      if value?
        this['_'+key] = value
        for dep in @getDependencyNames(value)
          qmlEngine.defineDependency(@id, key, dep.id, dep.key)

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
  color: null
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




#item = qmlEngine.parseQML str
#canvas = qmlEngine.findItem('canvas')

#if window?
#  atom.dom ()->
Root = window
window.Root = Root
exportNames 'Item', 'Shape', 'Text', 'Rectangle', 'Circle', 'QMLEngine', 'qmlView', 'qmlEngine'
#console.log convertQML str