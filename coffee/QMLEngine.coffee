exportNames = (names...) ->
  for cl in names
    Root[cl] = eval '('+cl+')'
  return null


#TODO: move global elcount in class QMLParser
elcount=0
class QMLParser
  elcount: 0
  replaces: [
    #  re: /\;/g
    #  repl: "\n"
    #,
      re: /(\w+)\s*\:\s*\[/ #array
      repl: "$1: {"
    ,
      re: /\]/ #array
      repl: "},"
    ,
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
#      console.log "updating #{dep.obj.id} #{dep.key} "
      dep.obj[dep.key] = dep.obj[dep.key]

  getNewId: ()->
    return 'obj'+@count++

  findItem: (id)->
    return @items[id]
  registerItem: (obj)->
    @items[obj.id] = obj
  unregisterItem: (obj)->
    @items[obj.id] == undefined

  createObjects: (obj, parent) ->
    parent = null if not parent?
    res = null
    switch obj.type
      when "Rectangle" then res =  new Rectangle parent, obj
      when "Text" then res = new Text parent, obj
      when "MouseArea" then res = new MouseArea parent, obj
      when "Row" then res = new Row parent, obj
      when "Column" then res = new Column parent, obj
      when "Repeater" then res = new Repeater parent, obj

    re = /elem\d+/
    return unless res?


    for own key, child of obj
      continue unless typeof key == 'string'
      if re.test key
#        if res.type == 'Repeater'

          #@unregisterItem(res)
 #         return null
  #      else
        ch = @createObjects child, res
        res.children.push ch if ch? and res.type != 'Repeater'
        res._repeatedItem = child if res.type == 'Repeater'

      #res.children.push @createObjects child, res
    res.ready()
    return res

qmlEngine = new QMLEngine()
qmlParser  = new QMLParser()

exportNames 'qmlEngine', 'qmlParser'
