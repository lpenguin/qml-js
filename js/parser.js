(function() {
  var AnchorLine, AnchorTypes, Circle, Item, MouseArea, QMLEngine, QMLParser, QMLView, Rectangle, Root, Shape, Text, elcount, exportNames, qmlEngine, qmlParser, qmlView;
  var __hasProp = Object.prototype.hasOwnProperty, __slice = Array.prototype.slice, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  }, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  elcount = 0;
  QMLParser = (function() {
    function QMLParser() {}
    QMLParser.prototype.elcount = 0;
    QMLParser.prototype.replaces = [
      {
        re: /on(\w+)\s*:\s*\{/,
        repl: 'on$1: function(){'
      }, {
        re: /on(\w+)\s*:\s*(\w[^\{]+)/,
        repl: "on$1: function()\{$2\}"
      }, {
        re: /(\w+)\s*{/g,
        repl: function(tmpl, found) {
          return 'elem' + (elcount++) + ': { "type": "' + found + '",';
        }
      }, {
        re: /(})/,
        repl: '$1,'
      }, {
        re: /([\w\.]+)\:\s*(\d+)$/,
        repl: '"$1": $2,'
      }, {
        re: /([\w\.]+)\s*\:\s*\"([^\"]+)"/,
        repl: '\"$1\": \"\\\"$2\\\"\",'
      }, {
        re: /([\w\.]+)\s*\:\s*([^\"\']+)$/,
        repl: '"$1": "$2",'
      }, {
        re: /([\w\.]+)\s*\:\s*\'([^\']+)'/,
        repl: '\"$1\": \"\\\"$2\\\"\",'
      }, {
        re: /import QtQuick [\d\.]+/,
        repl: ''
      }
    ];
    QMLParser.prototype.parseQML = function(qmlstr) {
      var line, lines, obj, replace, replaced, str, strs, _i, _j, _len, _len2, _ref;
      this.elcount = 0;
      lines = qmlstr.split(/[\n\;]/);
      strs = [];
      for (_i = 0, _len = lines.length; _i < _len; _i++) {
        line = lines[_i];
        replaced = false;
        _ref = this.replaces;
        for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
          replace = _ref[_j];
          if (line.match(replace.re)) {
            strs.push(line.replace(replace.re, replace.repl));
            replaced = true;
            break;
          }
        }
        if (!replaced) {
          strs.push(line);
        }
      }
      str = strs.join('\n').replace(/,$/, '');
      console.log(str);
      obj = eval("({" + str + "})");
      return obj['elem0'];
    };
    QMLParser.prototype.parse = function(str) {
      return this.parseQML(str);
    };
    return QMLParser;
  })();
  QMLEngine = (function() {
    function QMLEngine() {}
    QMLEngine.prototype.items = {};
    QMLEngine.prototype.count = 0;
    QMLEngine.prototype.evaluate = function(str, context) {
      with(context){
      r=eval(str)
    }
    ;      return r;
    };
    QMLEngine.prototype.depencities = {};
    QMLEngine.prototype.exportAll = function() {
      var item, name, _ref, _results;
      _ref = this.items;
      _results = [];
      for (name in _ref) {
        item = _ref[name];
        _results.push(Root[name] = item);
      }
      return _results;
    };
    QMLEngine.prototype["export"] = function(item) {
      return Root[item.id] = item;
    };
    QMLEngine.prototype.defineDependency = function(id, key, depid, depkey) {
      var dependencyName, obj;
      obj = this.findItem(id);
      if (depid === 'this') {
        depid = id;
      }
      if (depid === 'parent') {
        depid = obj.parent.id;
      }
      if (depkey === 'this') {
        depkey = '*';
      }
      dependencyName = depid + '/' + depkey;
      if (!(this.depencities[depid] != null)) {
        this.depencities[depid] = {};
      }
      if (!(this.depencities[depid][depkey] != null)) {
        this.depencities[depid][depkey] = [];
      }
      return this.depencities[depid][depkey].push({
        obj: obj,
        key: key
      });
    };
    QMLEngine.prototype.getDepencities = function(id, prop) {
      var d, dep, res, _i, _j, _len, _len2, _ref, _ref2;
      dep = this.depencities[id];
      if (!dep) {
        return null;
      }
      res = [];
      if (dep['*']) {
        _ref = dep['*'];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          d = _ref[_i];
          res.push(d);
        }
      }
      if (dep[prop]) {
        _ref2 = dep[prop];
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          d = _ref2[_j];
          res.push(d);
        }
      }
      if (!res.length) {
        return null;
      }
      return res;
    };
    QMLEngine.prototype.updateDepencities = function(id, key, newvalue) {
      var dep, deps, _i, _len, _results;
      qmlView.updateDepencities(id, key, newvalue);
      deps = this.getDepencities(id, key);
      if (!deps) {
        return;
      }
      _results = [];
      for (_i = 0, _len = deps.length; _i < _len; _i++) {
        dep = deps[_i];
        console.log("updating " + dep.obj.id + " " + dep.key + " ");
        _results.push(dep.obj[dep.key] = dep.obj[dep.key]);
      }
      return _results;
    };
    QMLEngine.prototype.getNewId = function() {
      return 'obj' + this.count++;
    };
    QMLEngine.prototype.findItem = function(id) {
      return this.items[id];
    };
    QMLEngine.prototype.registerItem = function(obj) {
      return this.items[obj.id] = obj;
    };
    QMLEngine.prototype.createObjects = function(obj, parent) {
      var child, key, re, res;
      if (!(parent != null)) {
        parent = null;
      }
      res = null;
      switch (obj.type) {
        case "Rectangle":
          res = new Rectangle(parent, obj);
          break;
        case "Text":
          res = new Text(parent, obj);
          break;
        case "MouseArea":
          res = new MouseArea(parent, obj);
      }
      re = /elem\d+/;
      if (res == null) {
        return;
      }
      for (key in obj) {
        if (!__hasProp.call(obj, key)) continue;
        child = obj[key];
        if (typeof key !== 'string') {
          continue;
        }
        if (re.test(key)) {
          res.childs.push(this.createObjects(child, res));
        }
      }
      return res;
    };
    return QMLEngine;
  })();
  QMLView = (function() {
    QMLView.prototype.domlinks = null;
    function QMLView() {
      this.domlinks = {};
    }
    QMLView.prototype.createElement = function(el, parent) {
      var child, prop, res, subelement, _i, _j, _len, _len2, _ref, _ref2;
      res = null;
      switch (el.type) {
        case 'Rectangle':
          res = this.createRectangle(el, parent);
          break;
        case 'Text':
          res = this.createText(el, parent);
          break;
        case 'MouseArea':
          res = this.createMouseArea(el, parent);
      }
      if (!(res != null)) {
        return null;
      }
      res.attr({
        id: "qml-" + el.id
      });
      this.domlinks[el.id] = res;
      _ref = el.getProperties();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        prop = _ref[_i];
        this.setDomProperty(res, prop, el);
      }
      _ref2 = el.childs;
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        child = _ref2[_j];
        subelement = this.createElement(child, res);
      }
      return res;
    };
    QMLView.prototype.updateDepencities = function(id, property, newvalue) {
      var domobj, el;
      el = qmlEngine.findItem(id);
      domobj = this.domlinks[id];
      if (!domobj) {
        return;
      }
      return this.setDomProperty(domobj, property, el);
    };
    QMLView.prototype.setDomProperty = function(domobj, property, el) {
      var f, value;
      f = this.propFunctions[property];
      if (!f) {
        return;
      }
      value = el[property];
      return f(domobj, value, el);
    };
    QMLView.prototype.createRectangle = function(el, parent) {
      var domobj;
      domobj = atom.dom.create('div').appendTo(parent);
      domobj.addClass('Rectangle');
      return domobj;
    };
    QMLView.prototype.createText = function(el, parent) {
      var domobj;
      domobj = atom.dom.create('span').appendTo(parent);
      domobj.addClass('Text');
      return domobj;
    };
    QMLView.prototype.createMouseArea = function(el, parent) {
      var domobj;
      domobj = atom.dom.create('div').appendTo(parent);
      domobj.addClass('MouseArea');
      domobj.bind({
        click: function(e) {
          with(el){
      eval(el.onClicked.toString()+"()");
      } ;          return false;
        }
      });
      return domobj;
    };
    QMLView.prototype.getCSSMetrics = function(domobj) {
      var h, metric, w;
      domobj = domobj.first;
      w = domobj.offsetWidth;
      h = domobj.offsetHeight;
      metric = {
        width: w,
        height: h,
        left: domobj.offsetLeft,
        top: domobj.offsetTop,
        right: domobj.offsetLeft + w,
        bottom: domobj.offsetTop + h
      };
      return metric;
    };
    QMLView.prototype.propFunctions = {
      width: function(domobj, v) {
        return domobj.css({
          width: v
        });
      },
      height: function(domobj, v) {
        return domobj.css({
          height: v
        });
      },
      x: function(domobj, v, el) {
        return domobj.css({
          left: !el['anchor.left'] && !el['anchor.right'] ? v : void 0
        });
      },
      y: function(domobj, v, el) {
        return domobj.css({
          top: !el['anchor.top'] && !el['anchor.bottom'] ? v : void 0
        });
      },
      color: function(domobj, v, el) {
        if (el.type === 'Text') {
          return domobj.css({
            'color': v
          });
        } else {
          return domobj.css({
            'background-color': v
          });
        }
      },
      text: function(domobj, v) {
        return domobj.html(v);
      },
      'border.width': function(domobj, v) {
        return domobj.css({
          'border-width': v + 'px',
          'border-style': 'solid'
        });
      },
      'border.color': function(domobj, v) {
        return domobj.css({
          'border-color': v
        });
      },
      'anchors.centerIn': function(domobj, v, el) {
        var m, parentm;
        if (!el.parent) {
          return;
        }
        m = qmlView.getCSSMetrics(domobj);
        parentm = qmlView.getCSSMetrics(qmlView.domlinks[el.parent.id]);
        domobj.css({
          left: (parentm.width / 2 - m.width / 2) + "px",
          top: (parentm.height / 2 - m.height / 2) + "px"
        });
        return domobj;
      }
    };
    return QMLView;
  })();
  qmlEngine = new QMLEngine();
  qmlView = new QMLView();
  qmlParser = new QMLParser();
  exportNames = function() {
    var cl, names, _i, _len;
    names = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    for (_i = 0, _len = names.length; _i < _len; _i++) {
      cl = names[_i];
      Root[cl] = eval('(' + cl + ')');
    }
    return null;
  };
  AnchorTypes = {
    left: 0,
    right: 1,
    top: 2,
    bottom: 3
  };
  AnchorLine = (function() {
    AnchorLine.prototype.type = AnchorTypes.left;
    AnchorLine.prototype.item = null;
    function AnchorLine(type, item) {
      this.type = type;
      this.item = item;
    }
    AnchorLine.prototype.value = function(anchoreditem) {
      switch (this.type) {
        case AnchorTypes.left:
          if (this.item.isParent(anchoreditem)) {
            return 0;
          }
          if (this.item.isSibling(anchoreditem)) {
            return this.item.x;
          }
          throw Error("Cannot anchor to an item that isn't a parent or sibling");
          break;
        case AnchorTypes.right:
          if (this.item.isParent(anchoreditem)) {
            return this.item.width;
          }
          if (this.item.isSibling(anchoreditem)) {
            return this.item.x + this.item.width;
          }
          throw Error("Cannot anchor to an item that isn't a parent or sibling");
          break;
        case AnchorTypes.top:
          if (this.item.isParent(anchoreditem)) {
            return 0;
          }
          if (this.item.isSibling(anchoreditem)) {
            return this.item.height;
          }
          throw Error("Cannot anchor to an item that isn't a parent or sibling");
          break;
        case AnchorTypes.bottom:
          if (this.item.isParent(anchoreditem)) {
            return this.item.height;
          }
          if (this.item.isSibling(anchoreditem)) {
            return this.item.y + this.item.height;
          }
          throw Error("Cannot anchor to an item that isn't a parent or sibling");
      }
      throw Error("Undefined anchor type");
    };
    return AnchorLine;
  })();
  ({
    isValid: function(item) {
      return item.parent === this.item || item.parent === this.item.parent;
    }
  });
  Item = (function() {
    Item.prototype.parent = null;
    Item.prototype.childs = null;
    Item.prototype.id = null;
    Item.prototype.type = 'Item';
    Item.prototype.x = 0;
    Item.prototype.y = 0;
    Item.prototype.width = 0;
    Item.prototype.height = 0;
    Item.prototype.color = "''";
    Item.prototype['anchors.centerIn'] = null;
    Item.prototype['anchors.fill'] = null;
    Item.prototype['anchors.left'] = null;
    Item.prototype['anchors.right'] = null;
    Item.prototype['anchors.top'] = null;
    Item.prototype['anchors.bottom'] = null;
    Item.prototype['border.color'] = '"black"';
    Item.prototype['border.width'] = 0;
    Item.prototype.anchors = {
      'anchors.left': function(v) {
        if (v == null) {
          return;
        }
        return this.x = v.value(this);
      },
      'anchors.right': function(v) {
        if (v == null) {
          return;
        }
        return this.x = v.value(this) - this.width;
      },
      'anchors.top': function(v) {
        if (v == null) {
          return;
        }
        return this.y = v.value(this);
      },
      'anchors.bottom': function(v) {
        if (v == null) {
          return;
        }
        return this.y = v.value(this) - this.height;
      },
      'anchors.fill': function(v) {
        if (v == null) {
          return;
        }
        this.y = 0;
        this.x = 0;
        this.width = v.width;
        return this.height = v.height;
      }
    };
    Item.prototype.dynamic = {
      'left': {
        get: function() {
          return new AnchorLine(AnchorTypes.left, this);
        }
      },
      'right': {
        get: function() {
          return new AnchorLine(AnchorTypes.right, this);
        },
        deps: ['width']
      },
      'top': {
        get: function() {
          return new AnchorLine(AnchorTypes.top, this);
        }
      },
      'bottom': {
        get: function() {
          return new AnchorLine(AnchorTypes.bottom, this);
        },
        deps: ['height']
      }
    };
    Item.prototype.isSibling = function(item) {
      return this.parent === item.parent;
    };
    Item.prototype.isParent = function(item) {
      return this === item.parent;
    };
    Item.prototype.appendSetter = function(prop, setter) {
      var oldsetter;
      oldsetter = this.__lookupSetter__(prop);
      return this.__defineSetter__(prop, function(v) {
        setter.call(this, v);
        return oldsetter.call(this, v);
      });
    };
    Item.prototype.defineGetter = function(propName) {
      return this.__defineGetter__(propName, function() {
        return qmlEngine.evaluate(this["_" + propName], this);
      });
    };
    Item.prototype.defineSetter = function(propName) {
      return this.__defineSetter__(propName, function(value) {
        if (typeof value === "string") {
          value = "\"" + value + "\"";
        }
        this['_' + propName] = value;
        return qmlEngine.updateDepencities(this.id, propName, value);
      });
    };
    Item.prototype.readOptions = function(options) {
      var prop, _i, _len, _ref, _results;
      _ref = this.getProperties(true);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        prop = _ref[_i];
        if (options[prop] == null) {
          continue;
        }
        _results.push(this[prop] = options[prop]);
      }
      return _results;
    };
    function Item(parent, options) {
      var prop, setter, _ref;
      this.childs = [];
      if (!(options != null)) {
        this.parent = null;
        options = parent;
      } else {
        if (typeof parent === 'object') {
          this.parent = parent;
        } else {
          this.parent = qmlEngine.findItem(parent);
        }
      }
      this.id = options.id || qmlEngine.getNewId();
      qmlEngine.registerItem(this);
      qmlEngine["export"](this);
      this.defineDynamicProperties();
      this.readOptions(options);
      console.log('created: ' + this.type);
      console.log(' with id: ' + this.id);
      if (this.parent) {
        console.log(' with parent: ' + this.parent.id);
      }
      this.defineGettersSetters();
      _ref = this.anchors;
      for (prop in _ref) {
        setter = _ref[prop];
        this.appendSetter(prop, setter);
        this[prop] = this[prop];
      }
    }
    Item.prototype.defineDynamicSetter = function(thisid, propname) {
      return this.__defineSetter__(propname, function(v) {
        return qmlEngine.updateDepencities(this.id, propname, v);
      });
    };
    Item.prototype.defineDynamicProperties = function() {
      var dep, prop, propname, _i, _len, _ref, _ref2;
      _ref = this.dynamic;
      for (propname in _ref) {
        if (!__hasProp.call(_ref, propname)) continue;
        prop = _ref[propname];
        if (prop.get) {
          this.__defineGetter__(propname, prop.get);
        }
        this.defineDynamicSetter(this.id, propname);
        if (prop.deps) {
          _ref2 = prop.deps;
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            dep = _ref2[_i];
            qmlEngine.defineDependency(this.id, propname, this.id, dep);
          }
        }
      }
    };
    Item.prototype.getProperties = function(getnullprops) {
      var key, res, skipnames, value;
      if (getnullprops == null) {
        getnullprops = false;
      }
      res = [];
      skipnames = ['parent', 'id', 'childs', 'type', 'dynamic'];
      for (key in this) {
        value = this[key];
        if (__indexOf.call(skipnames, key) >= 0 || typeof this[key] === 'function' || key.match(/^_/)) {
          continue;
        }
        if (!(value != null) && !getnullprops) {
          continue;
        }
        res.push(key);
      }
      return res;
    };
    Item.prototype.getPropertiesObj = function(getnullprops) {
      var key, res, skipnames, value;
      if (getnullprops == null) {
        getnullprops = false;
      }
      res = {};
      skipnames = ['parent', 'id', 'childs', 'type', 'dynamic'];
      for (key in this) {
        value = this[key];
        if (__indexOf.call(skipnames, key) >= 0 || typeof this[key] === 'function' || key.match(/^_/)) {
          continue;
        }
        if (!(value != null) && !getnullprops) {
          continue;
        }
        res[key] = value;
      }
      return res;
    };
    Item.prototype.defineGettersSetters = function() {
      var dep, key, value, _i, _len, _ref, _ref2;
      _ref = this.getPropertiesObj(true);
      for (key in _ref) {
        value = _ref[key];
        if (this.dynamic[key] != null) {
          continue;
        }
        if (value != null) {
          this['_' + key] = value;
          _ref2 = this.getDependencyNames(value);
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            dep = _ref2[_i];
            qmlEngine.defineDependency(this.id, key, dep.id, dep.key);
          }
        }
        this.defineGetter(key);
        this.defineSetter(key);
      }
      return null;
    };
    Item.prototype.getDependencyNames = function(nameStr) {
      var digre, id, key, m, name, namere, r, res, strre, _i, _len;
      strre = new RegExp('^(\"|\').*(\"|\')$');
      digre = new RegExp('^[0-9.]+$');
      if (typeof nameStr !== 'string') {
        return [];
      }
      nameStr.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
      if (strre.test(nameStr) || digre.test(nameStr)) {
        return [];
      }
      namere = /\w+[\w\.]*\w*/g;
      m = nameStr.match(namere);
      if (!m) {
        return [];
      }
      res = [];
      for (_i = 0, _len = m.length; _i < _len; _i++) {
        name = m[_i];
        if (digre.test(name)) {
          continue;
        }
        if (name === 'parent') {
          res.push({
            id: 'parent',
            key: 'this'
          });
          continue;
        }
        r = name.split('.');
        if (r.length === 1) {
          id = 'this';
          key = name;
        } else {
          id = r.shift();
          key = r.join('.');
        }
        res.push({
          id: id,
          key: key
        });
      }
      return res;
    };
    return Item;
  })();
  Shape = (function() {
    __extends(Shape, Item);
    function Shape() {
      Shape.__super__.constructor.apply(this, arguments);
    }
    Shape.prototype.type = 'Shape';
    return Shape;
  })();
  Text = (function() {
    __extends(Text, Shape);
    function Text() {
      Text.__super__.constructor.apply(this, arguments);
    }
    Text.prototype.text = '""';
    Text.prototype.type = 'Text';
    return Text;
  })();
  Circle = (function() {
    __extends(Circle, Shape);
    function Circle() {
      Circle.__super__.constructor.apply(this, arguments);
    }
    Circle.prototype.radius = 0;
    Circle.prototype.type = 'Circle';
    return Circle;
  })();
  Rectangle = (function() {
    __extends(Rectangle, Shape);
    function Rectangle() {
      Rectangle.__super__.constructor.apply(this, arguments);
    }
    Rectangle.prototype.radius = null;
    Rectangle.prototype.type = 'Rectangle';
    return Rectangle;
  })();
  MouseArea = (function() {
    __extends(MouseArea, Item);
    function MouseArea() {
      MouseArea.__super__.constructor.apply(this, arguments);
    }
    MouseArea.prototype.onClicked = null;
    MouseArea.prototype.type = 'MouseArea';
    return MouseArea;
  })();
  Root = window;
  window.Root = Root;
  exportNames('Item', 'Shape', 'Text', 'Rectangle', 'Circle', 'QMLEngine', 'qmlView', 'qmlEngine', 'qmlParser');
}).call(this);
