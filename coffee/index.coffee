MdsRendererClass = require './js/classes/mds_renderer'
MdsRenderer = new MdsRendererClass
MdsRenderer.requestAccept()

$ ->
  CodeMirror.fromTextArea $('#editor')[0],
    mode: 'markdown'
