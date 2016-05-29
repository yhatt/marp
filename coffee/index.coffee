{shell}        = require 'electron'
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
  previewInitialized: false
  _lockChangedStatus: false
  _imageDirectories: null

  constructor: (@codeMirror, @preview) ->
    @initializeEditor()
    @initializePreview()

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

  initializePreview: =>
    # Fix minimized preview (#20)
    # [Note] https://github.com/electron/electron/issues/4882
    $(@preview.shadowRoot).append('<style>object{min-width:0;min-height:0;}</style>')

    $(@preview)
      .on 'ipc-message', (ev) =>
        e = ev.originalEvent

        switch e.channel
          when 'initializedSlide'
            $('body').addClass 'initialized-slide'
          when 'rulerChanged'
            @refreshPage e.args[0]
          when 'linkTo'
            @openLink e.args[0]

      .on 'new-window', (e) =>
        e.preventDefault()
        @openLink e.originalEvent.url

      .on 'did-finish-load', (e) =>
        @preview.send 'currentPage', 1
        @preview.send 'setImageDirectories', @_imageDirectories if @_imageDirectories
        @preview.send 'render', @codeMirror.getValue()

        MdsRenderer.sendToMain 'previewInitialized'
        @previewInitialized = true

  openLink: (link) =>
    shell.openExternal link if /^https?:\/\/.+/.test(link)

  initializeEditor: =>
    @codeMirror.on 'change', (cm, chg) =>
      @preview.send 'render', cm.getValue()
      MdsRenderer.sendToMain 'setChangedStatus', true if !@_lockChangedStatus

    @codeMirror.on 'cursorActivity', (cm) => window.setTimeout (=> @refreshPage()), 5

  setImageDirectories: (directories) =>
    if @previewInitialized
      @preview.send 'setImageDirectories', directories
      @preview.send 'render', @codeMirror.getValue()
    else
      @_imageDirectories = directories

$ ->
  editorStates = new EditorStates(
    CodeMirror.fromTextArea($('#editor')[0],
      mode: 'gfm'
      theme: 'marp'
      lineWrapping: true
      lineNumbers: false
      dragDrop: false
      extraKeys:
        Enter: 'newlineAndIndentContinueMarkdownList'
    ),
    $('#preview')[0]
  )

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
      editorStates.codeMirror.clearHistory()
      editorStates._lockChangedStatus = false

    .on 'setImageDirectories', (directories) -> editorStates.setImageDirectories directories

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

      $('#preview-modes').removeClass('disabled')
      $('.viewmode-btn[data-viewmode]').removeClass('active')
        .filter("[data-viewmode='#{mode}']").addClass('active')

    .on 'editCommand', (command) -> editorStates.codeMirror.execCommand(command)

    .on 'openDevTool', ->
      if editorStates.preview.isDevToolsOpened()
        editorStates.preview.closeDevTools()
      else
        editorStates.preview.openDevTools()

    .on 'setSplitter', (spliiterPos) -> setSplitter spliiterPos

  # Initialize
  editorStates.codeMirror.focus()
  editorStates.refreshPage()
