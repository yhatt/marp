clsMdsRenderer = require './js/classes/mds_renderer'
MdsRenderer    = new clsMdsRenderer
MdsRenderer.requestAccept()

CodeMirror = require 'codemirror'
require 'codemirror/mode/xml/xml'
require 'codemirror/mode/markdown/markdown'
require 'codemirror/mode/gfm/gfm'
require 'codemirror/addon/edit/continuelist'

$ ->
  editor  = $('#editor')[0]
  preview = $('#preview')[0]

  $(preview).on 'ipc-message', (event) ->
    console.log event.originalEvent.channel

  editorCm = CodeMirror.fromTextArea editor,
    mode: 'gfm'
    theme: 'mdslide'
    lineWrapping: true
    lineNumbers: false
    dragDrop: false
    extraKeys:
      Enter: 'newlineAndIndentContinueMarkdownList'

  editorCm.on 'change', (cm, chg) ->
    preview.send 'render', cm.getValue()
