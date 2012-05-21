Root = window
window.Root = Root

Root.exportNames = (names...) ->
  for cl in names
    Root[cl] = eval '('+cl+')'
  return null