clsMdsRenderer = require './js/classes/mds_renderer'
MdsRenderer    = new clsMdsRenderer
MdsRenderer.requestAccept()

clsMdsMarkdown = require './js/classes/mds_markdown'
Markdown       = new clsMdsMarkdown

CodeMirror = require 'codemirror'
require 'codemirror/mode/xml/xml'
require 'codemirror/mode/markdown/markdown'
require 'codemirror/mode/gfm/gfm'
require 'codemirror/addon/edit/continuelist'

$ ->
  editor = $('#editor')[0]
  editorCm = CodeMirror.fromTextArea editor,
    mode: 'gfm'
    theme: 'base16-light'
    lineWrapping: true
    lineNumbers: false
    dragDrop: false
    extraKeys:
      Enter: 'newlineAndIndentContinueMarkdownList'

  editorCm.on 'change', (cm, chg) ->
    $('#preview').html Markdown.parse(cm.getValue())
