
  atom.dom(function() {
    var root;
    root = atom.dom('div').first;
    atom.dom('#incwidth').bind({
      'click': function() {
        return canvas.width += 100;
      }
    });
    atom.dom('#incheight').bind({
      'click': function() {
        return canvas.height += 100;
      }
    });
    atom.dom('#incx').bind({
      'click': function() {
        return canvas.x += 100;
      }
    });
    atom.dom('#incy').bind({
      'click': function() {
        return canvas.y += 100;
      }
    });
    return atom.dom('script[type="text/qml"]').each(function(el) {
      return atom.ajax({
        url: el.src,
        type: 'plain',
        method: 'get',
        onLoad: function(data) {
          var r, rootElem;
          data = qmlParser.parse(data);
          rootElem = qmlEngine.createObjects(data);
          qmlEngine.exportAll();
          r = qmlView.createElement(rootElem, root);
          return r.appendTo(root);
        }
      });
    });
  });
