{shell, webFrame} = require 'electron'
MdsMenu           = require './js/classes/mds_menu'
clsMdsRenderer    = require './js/classes/mds_renderer'
MdsRenderer       = new clsMdsRenderer
MdsRenderer.requestAccept()

webFrame.setZoomLevelLimits(1, 1)

CodeMirror = require 'codemirror'
require 'codemirror/mode/xml/xml'
require 'codemirror/mode/markdown/markdown'
require 'codemirror/mode/gfm/gfm'
require 'codemirror/addon/edit/continuelist'

class EditorStates
  rulers: []
  currentPage: null
  previewInitialized: false
  lastRendered: {}

  _lockChangedStatus: false
  _imageDirectory: null

  constructor: (@codeMirror, @preview) ->
    @initializeEditor()
    @initializePreview()

    @menu = new MdsMenu [
      { label: '&Undo', accelerator: 'CmdOrCtrl+Z', click: (i, w) => @codeMirror.execCommand 'undo' if w and !w.mdsWindow.freeze }
      { label: '&Redo', accelerator: 'Shift+CmdOrCtrl+Z', click: (i, w) => @codeMirror.execCommand 'redo' if w and !w.mdsWindow.freeze }
      { type: 'separator' }
      { label: 'Cu&t', accelerator: 'CmdOrCtrl+X', role: 'cut' }
      { label: '&Copy', accelerator: 'CmdOrCtrl+C', role: 'copy' }
      { label: '&Paste', accelerator: 'CmdOrCtrl+V', role: 'paste' }
      { label: '&Delete', role: 'delete' }
      { label: 'Select &All', accelerator: 'CmdOrCtrl+A', click: (i, w) => @codeMirror.execCommand 'selectAll' if w and !w.mdsWindow.freeze }
      { type: 'separator', platform: 'darwin' }
      { label: 'Services', role: 'services', submenu: [], platform: 'darwin' }
    ]

  refreshPage: (rulers) =>
    @rulers = rulers if rulers?
    page    = 1

    lineNumber = @codeMirror.getCursor().line || 0
    for rulerLine in @rulers
      page++ if rulerLine <= lineNumber

    if @currentPage != page
      @currentPage = page
      @preview.send 'currentPage', @currentPage if @previewInitialized

    $('#page-indicator').text "Page #{@currentPage} / #{@rulers.length + 1}"

  initializePreview: =>
    $(@preview)
      .on 'dom-ready', =>
        # Fix minimized preview (#20)
        # [Note] https://github.com/electron/electron/issues/4882
        $(@preview.shadowRoot).append('<style>object{min-width:0;min-height:0;}</style>')

      .on 'ipc-message', (ev) =>
        e = ev.originalEvent

        switch e.channel
          when 'rulerChanged'
            @refreshPage e.args[0]
          when 'linkTo'
            @openLink e.args[0]
          when 'rendered'
            @lastRendered = e.args[0]
            unless @previewInitialized
              MdsRenderer.sendToMain 'previewInitialized'

              @previewInitialized = true
              $('body').addClass 'initialized-slide'
          else
            MdsRenderer._call_event e.channel, e.args...

      .on 'new-window', (e) =>
        e.preventDefault()
        @openLink e.originalEvent.url

      .on 'did-finish-load', (e) =>
        @preview.send 'currentPage', 1
        @preview.send 'setImageDirectory', @_imageDirectory
        @preview.send 'render', @codeMirror.getValue()

  openLink: (link) =>
    shell.openExternal link if /^https?:\/\/.+/.test(link)

  initializeEditor: =>
    @codeMirror.on 'contextmenu', (cm, e) =>
      e.preventDefault()
      @codeMirror.focus()
      @menu.popup()
      false

    @codeMirror.on 'change', (cm, chg) =>
      @preview.send 'render', cm.getValue()
      MdsRenderer.sendToMain 'setChangedStatus', true if !@_lockChangedStatus

    @codeMirror.on 'cursorActivity', (cm) => window.setTimeout (=> @refreshPage()), 5

  setImageDirectory: (directory) =>
    if @previewInitialized
      @preview.send 'setImageDirectory', directory
      @preview.send 'render', @codeMirror.getValue()
    else
      @_imageDirectory = directory

  insertImage: (filePath) => @codeMirror.replaceSelection("![](#{filePath})\n")

  updateGlobalSetting: (prop, value) =>
    latestPos = null

    for obj in (@lastRendered?.settingsPosition || [])
      latestPos = obj if obj.property is prop

    if latestPos?
      @codeMirror.replaceRange(
        "#{prop}: #{value}",
        CodeMirror.Pos(latestPos.lineIdx, latestPos.from),
        CodeMirror.Pos(latestPos.lineIdx, latestPos.from + latestPos.length),
      )
    else
      @codeMirror.replaceRange(
        "<!-- #{prop}: #{value} -->\n\n",
        CodeMirror.Pos(@codeMirror.firstLine(), 0)
      )

loadingState = 'loading'

do ->
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
      return false unless (f = e.originalEvent.dataTransfer?.files?[0])?

      if f.type.startsWith('image')
        editorStates.insertImage f.path
      else if f.type.startsWith('text') || f.type is ''
        MdsRenderer.sendToMain 'loadFromFile', f.path if f.path?
      false

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

  responsePdfOpts = null

  # Events
  MdsRenderer
    .on 'publishPdf', (fname) ->
      editorStates.codeMirror.getInputField().blur()
      $('body').addClass 'exporting-pdf'

      editorStates.preview.send 'requestPdfOptions', { filename: fname }

    .on 'responsePdfOptions', (opts) ->
      # Wait loading resources
      startPublish = ->
        if loadingState is 'loading'
          setTimeout startPublish, 250
        else
          editorStates.preview.printToPDF
            marginsType: 1
            pageSize: opts.exportSize
            printBackground: true
          , (err, data) ->
            unless err
              MdsRenderer.sendToMain 'writeFile', opts.filename, data, 'unfreeze'
            else
              MdsRenderer.sendToMain 'unfreeze'

      setTimeout startPublish, 500

    .on 'unfreezed', ->
      editorStates.preview.send 'unfreeze'
      $('body').removeClass 'exporting-pdf'

    .on 'loadText', (buffer) ->
      editorStates._lockChangedStatus = true
      editorStates.codeMirror.setValue buffer
      editorStates.codeMirror.clearHistory()
      editorStates._lockChangedStatus = false

    .on 'setImageDirectory', (directories) -> editorStates.setImageDirectory directories

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
    .on 'setTheme', (theme) -> editorStates.updateGlobalSetting '$theme', theme
    .on 'themeChanged', (theme) -> MdsRenderer.sendToMain 'themeChanged', theme
    .on 'resourceState', (state) -> loadingState = state

  # Initialize
  editorStates.codeMirror.focus()
  editorStates.refreshPage()
