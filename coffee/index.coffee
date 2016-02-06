MdsRendererClass = require './js/classes/mds_renderer'
MdsRenderer = new MdsRendererClass
MdsRenderer.requestAccept()

CodeMirror = require 'codemirror'
require 'codemirror/mode/xml/xml'
require 'codemirror/mode/markdown/markdown'
require 'codemirror/mode/gfm/gfm'
require 'codemirror/addon/edit/continuelist'

$ ->
  CodeMirror.fromTextArea $('#editor')[0],
    mode: 'gfm'
    theme: 'base16-light'
    lineWrapping: true
    lineNumbers: false
    extraKeys:
      Enter: 'newlineAndIndentContinueMarkdownList'
