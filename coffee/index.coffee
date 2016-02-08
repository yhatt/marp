shell          = require('electron').shell
clsMdsRenderer = require './js/classes/mds_renderer'
MdsRenderer    = new clsMdsRenderer
MdsRenderer.requestAccept()

CodeMirror = require 'codemirror'
require 'codemirror/mode/xml/xml'
require 'codemirror/mode/markdown/markdown'
require 'codemirror/mode/gfm/gfm'
require 'codemirror/addon/edit/continuelist'

class EditorStates
  rulers: []
  currentPage: null

  constructor: (@codeMirror, @preview) ->
    @codeMirror.on 'change', (cm, chg) =>
      @preview.send 'render', cm.getValue()

    @codeMirror.on 'cursorActivity', (cm) =>
      window.setTimeout =>
        @refreshPage()
      , 10

    $(@preview).on 'did-finish-load', (e) =>
      @preview.send 'render', @codeMirror.getValue()

  refreshPage: (rulers) =>
    @rulers = rulers if rulers?
    page    = 1

    lineNumber = @codeMirror.getCursor().line
    for rulerLine in @rulers
      page++ if rulerLine <= lineNumber

    if @currentPage != page
      @currentPage = page
      @preview.send 'currentPage', @currentPage

$ ->
  editor  = $('#editor')[0]
  preview = $('#preview')[0]

  # Editor settings
  editorCm = CodeMirror.fromTextArea editor,
    mode: 'gfm'
    theme: 'mdslide'
    lineWrapping: true
    lineNumbers: false
    dragDrop: false
    extraKeys:
      Enter: 'newlineAndIndentContinueMarkdownList'

  editorStates = new EditorStates editorCm, preview

  # Markdown preview
  $(preview)
    .on 'ipc-message', (event) ->
      e = event.originalEvent

      switch e.channel
        when 'rulerChanged'
          editorStates.refreshPage e.args[0]

    .on 'new-window', (e) ->
      e.preventDefault()
      shell.openExternal e.originalEvent.url

    .on 'dom-ready', ->
      will_navigate_url = null

      $(preview)
        .on 'will-navigate', (e) -> will_navigate_url = e.originalEvent.url
        .on 'did-start-loading', (e) ->
          preview.stop()
          shell.openExternal will_navigate_url if will_navigate_url?
          will_navigate_url = null

  # Mode
  previewButtons = $('#preview-modes [data-class]')
  previewButtons.click ->
    previewButtons.removeClass 'active'
    $(this).addClass 'active'
    preview.send 'setClass', $(this).attr('data-class')

  # Publish PDF
  $('#export_to_pdf').click ->
    MdsRenderer.sendToMain 'exportPdfDialog'

  MdsRenderer.on 'publishPdf', (fname) ->
    preview.printToPDF
      marginsType: 1
      pageSize: 'A4'
      printBackground: true
      landscape: true
    , (err, data) -> MdsRenderer.sendToMain 'saveData', fname, data unless err


  # Intialize
  editorStates.refreshPage()
  editorCm.focus()
