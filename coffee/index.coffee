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
  _lockChangedStatus: false

  constructor: (@codeMirror, @preview) ->
    @codeMirror.on 'change', (cm, chg) =>
      @preview.send 'render', cm.getValue()
      MdsRenderer.sendToMain 'setChangedStatus', true if !@_lockChangedStatus

    @codeMirror.on 'cursorActivity', (cm) =>
      window.setTimeout =>
        @refreshPage()
      , 5

    $(@preview).on 'did-finish-load', (e) =>
      @preview.send 'currentPage', 1
      @preview.send 'render', @codeMirror.getValue()
      MdsRenderer.sendToMain 'previewInitialized'

  refreshPage: (rulers) =>
    @rulers = rulers if rulers?
    page    = 1

    lineNumber = @codeMirror.getCursor().line || 0
    for rulerLine in @rulers
      page++ if rulerLine <= lineNumber

    if @currentPage != page
      @currentPage = page
      @preview.send 'currentPage', @currentPage

    $('#page-indicator').text "Page #{@currentPage} / #{@rulers.length + 1}"

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
  $(editorStates.preview)
    .on 'ipc-message', (event) ->
      e = event.originalEvent

      switch e.channel
        when 'initializedSlide'
          $('body').addClass 'initialized-slide'
        when 'rulerChanged'
          editorStates.refreshPage e.args[0]

    .on 'new-window', (e) ->
      e.preventDefault()
      shell.openExternal e.originalEvent.url

    .on 'dom-ready', ->
      will_navigate_url = null

      $(editorStates.preview)
        .on 'will-navigate', (e) -> will_navigate_url = e.originalEvent.url
        .on 'did-start-loading', (e) ->
          preview.stop()
          shell.openExternal will_navigate_url if will_navigate_url?
          will_navigate_url = null

  # View modes
  $('.viewmode-btn[data-viewmode]').click -> MdsRenderer.sendToMain('viewMode', $(this).attr('data-viewmode'))

  # File D&D
  $(document)
    .on 'dragover',  -> false
    .on 'dragleave', -> false
    .on 'dragend',   -> false
    .on 'drop',      (e) =>
      e.preventDefault()

      file = e.originalEvent.dataTransfer?.files?[0]?.path
      MdsRenderer.sendToMain 'loadFromFile', file if file?

      return false

  # Splitter
  draggingSplitter      = false
  draggingSplitPosition = undefined

  setSplitter = (splitPoint) ->
    splitPoint = Math.min(0.8, Math.max(0.2, parseFloat(splitPoint)))

    $('.pane.markdown').css('flex-grow', splitPoint * 100)
    $('.pane.preview').css('flex-grow', (1 - splitPoint) * 100)

    return splitPoint

  $('.pane-splitter')
    .mousedown ->
      draggingSplitter = true
      draggingSplitPosition = undefined

    .dblclick ->
      MdsRenderer.sendToMain 'setConfig', 'splitterPosition', setSplitter(0.5)

  window.addEventListener 'mousemove', (e) ->
    if draggingSplitter
      draggingSplitPosition = setSplitter Math.min(Math.max(0, e.clientX), document.body.clientWidth) / document.body.clientWidth
  , false

  window.addEventListener 'mouseup', (e) ->
    draggingSplitter = false
    MdsRenderer.sendToMain 'setConfig', 'splitterPosition', draggingSplitPosition if draggingSplitPosition?
  , false

  # Events
  MdsRenderer
    .on 'publishPdf', (fname) ->
      editorStates.codeMirror.getInputField().blur()
      $('body').addClass 'exporting-pdf'

      editorStates.preview.printToPDF
        marginsType: 1
        pageSize: 'A4'
        printBackground: true
        landscape: true
      , (err, data) ->
        unless err
          MdsRenderer.sendToMain 'writeFile', fname, data, 'unfreeze'
        else
          MdsRenderer.sendToMain 'unfreeze'

    .on 'unfreezed', ->
      $('body').removeClass 'exporting-pdf'

    .on 'loadText', (buffer) ->
      editorStates._lockChangedStatus = true
      editorStates.codeMirror.setValue buffer
      editorStates._lockChangedStatus = false

    .on 'save', (fname, triggerOnSucceeded = null) ->
      MdsRenderer.sendToMain 'writeFile', fname, editorStates.codeMirror.getValue(), triggerOnSucceeded
      MdsRenderer.sendToMain 'initializeState', fname

    .on 'viewMode', (mode) ->
      switch mode
        when 'markdown'
          editorStates.preview.send 'setClass', ''
        when 'screen'
          editorStates.preview.send 'setClass', 'slide-view screen'
        when 'list'
          editorStates.preview.send 'setClass', 'slide-view list'

      $('.viewmode-btn[data-viewmode]').removeClass('active')
        .filter("[data-viewmode='#{mode}']").addClass('active')

    .on 'editCommand', (command) ->
      editorStates.codeMirror.execCommand(command)

    .on 'openDevTool', ->
      if editorStates.preview.isDevToolsOpened()
        editorStates.preview.closeDevTools()
      else
        editorStates.preview.openDevTools()

    .on 'setSplitter', (spliiterPos) -> setSplitter spliiterPos


  # Initialize
  editorStates.codeMirror.focus()
  editorStates.refreshPage()
