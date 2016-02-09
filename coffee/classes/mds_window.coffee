clsMdsManager  = require './mds_manager'
MdsMenu        = require './mds_menu'
BrowserWindow  = require 'browser-window'
extend         = require 'extend'
fs             = require 'fs'
dialog         = require('electron').dialog
MdsManager     = new clsMdsManager

module.exports = class MdsWindow
  @defOptions: {}

  browserWindow: null
  path: null
  changed: false

  constructor: (fileOpts = {}, @options = {}) ->
    @path = fileOpts?.path || null

    @browserWindow = do =>
      bw = new BrowserWindow extend(@constructor.defOptions, @options)
      @_window_id = bw.id

      bw.loadUrl "file://#{__dirname}/../../index.html##{@_window_id}"

      bw.webContents.on 'did-finish-load', =>
        @_windowLoaded = true
        @trigger 'load', fileOpts?.buffer || '', @path

      bw.on 'closed', =>
        @browserWindow = null
        @_setIsOpen false

      bw.mdsWindow = @
      bw

    @_setIsOpen true

  trigger: (evt, args...) =>
    @events[evt]?.apply(@, args)

  events:
    open: ->
      dialog.showOpenDialog @browserWindow,
        title: 'Open'
        filters: [
          { name: 'Markdown files', extensions: ['md', 'mdown'] }
          { name: 'Text file', extensions: ['txt'] }
          { name: 'All files', extensions: ['*'] }
        ]
        properties: ['openFile', 'createDirectory']

      , (fname) =>
        return unless fname?

        fs.readFile fname[0], (err, txt) =>
          return if err

          if !@path and not @changed
            @trigger 'load', txt.toString(), fname[0]
          else
            new MdsWindow
              path: fname[0]
              buffer: txt.toString()

    load: (buffer = '', path = null) ->
      @trigger 'initializeState', path
      @send 'loadText', buffer

    save: -> if @path then @send('save', @path) else @trigger 'saveAs'
    saveAs: ->
      dialog.showSaveDialog @browserWindow,
        title: 'Save as...'
        filters: [
          { name: 'Markdown files', extensions: ['md', 'mdown'] }
          { name: 'Text file', extensions: ['txt'] }
          { name: 'All files', extensions: ['*'] }
        ]
      , (fname) => @send 'save', fname if fname?

    writeFile: (fileName, data) ->
      fs.writeFile fileName, data, (err) ->
        console.log "Write file to #{fileName}." unless err

    exportPdfDialog: ->
      dialog.showSaveDialog @browserWindow,
        title: 'Export to PDF...'
        filters: [{ name: 'PDF file', extensions: ['pdf'] }]
      , (fname) =>
        return unless fname?
        @send 'publishPdf', fname

    initializeState: (filePath = null, changed = false) ->
      @path = filePath
      @changed = !!changed
      @refreshTitle()

    setChangedStatus: (changed) ->
      @changed = !!changed
      @refreshTitle()

    viewMode: (mode) -> @send 'viewMode', mode

  refreshTitle: =>
    @browserWindow?.setTitle "#{@options?.title || 'mdSlide'} - #{@getShortPath()}#{if @changed then ' *' else ''}"

  getShortPath: =>
    return '(untitled)' unless @path?
    @path.replace(/\\/g, '/').replace(/.*\//, '')

  isOpen: => @_isOpen
  _setIsOpen: (state) =>
    @_isOpen = !!state

    if @_isOpen
      MdsManager.addWindow @_window_id, @
    else
      MdsManager.removeWindow @_window_id

    return @_isOpen

  send: (evt, args...) =>
    return false unless @_windowLoaded and @browserWindow?
    @browserWindow.webContents.send 'MdsManagerSendEvent', evt, { from: null, to: @_window_id }, args
