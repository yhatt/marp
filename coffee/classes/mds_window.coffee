clsMdsManager  = require './mds_manager'
MdsMenu        = require './mds_menu'
BrowserWindow  = require 'browser-window'
extend         = require 'extend'
fs             = require 'fs'
dialog         = require('electron').dialog
MdsManager     = new clsMdsManager

module.exports = class MdsWindow
  @appWillQuit: false

  @defOptions:
    width: 860
    height: 400

  browserWindow: null
  path: null
  changed: false
  freeze: false

  _closeConfirmed: false

  constructor: (fileOpts = {}, @options = {}) ->
    @path = fileOpts?.path || null

    @browserWindow = do =>
      bw = new BrowserWindow extend(@constructor.defOptions, @options)
      @_window_id = bw.id

      bw.loadUrl "file://#{__dirname}/../../index.html##{@_window_id}"

      bw.webContents.on 'did-finish-load', =>
        @_windowLoaded = true
        @trigger 'load', fileOpts?.buffer || '', @path

      bw.on 'close', (e) =>
        if @freeze
          e.preventDefault()
          MdsWindow.appWillQuit = false
          return

        if @changed
          e.preventDefault()
          dialog.showMessageBox @browserWindow,
            type: 'question'
            buttons: ['Yes', 'No', 'Cancel']
            title: 'mdSlide'
            message: 'Are you sure?'
            detail: "#{@getShortPath()} has been modified. Do you want to save the changes?"
          , (result) =>
            switch result
              when 0 then @trigger 'save', 'forceClose'
              when 1 then @trigger 'forceClose'
              else
                MdsWindow.appWillQuit = false

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

    save: (triggerOnSucceeded = null) ->
      if @path then @send('save', @path, triggerOnSucceeded) else @trigger('saveAs', triggerOnSucceeded)

    saveAs: (triggerOnSucceeded = null) ->
      dialog.showSaveDialog @browserWindow,
        title: 'Save as...'
        filters: [
          { name: 'Markdown files', extensions: ['md', 'mdown'] }
          { name: 'Text file', extensions: ['txt'] }
          { name: 'All files', extensions: ['*'] }
        ]
      , (fname) =>
        if fname?
          @send 'save', fname, triggerOnSucceeded
        else
          MdsWindow.appWillQuit = false

    writeFile: (fileName, data, triggerOnSucceeded = null) ->
      fs.writeFile fileName, data, (err) =>
        unless err
          console.log "Write file to #{fileName}."
          @trigger triggerOnSucceeded if triggerOnSucceeded?
        else
          MdsWindow.appWillQuit = false

    forceClose: -> @browserWindow.destroy()

    exportPdfDialog: ->
      return if @freeze
      dialog.showSaveDialog @browserWindow,
        title: 'Export to PDF...'
        filters: [{ name: 'PDF file', extensions: ['pdf'] }]
      , (fname) =>
        return unless fname?
        @freeze = true
        @send 'publishPdf', fname

    initializeState: (filePath = null, changed = false) ->
      @path = filePath
      @changed = !!changed
      @refreshTitle()

    setChangedStatus: (changed) ->
      @changed = !!changed
      @refreshTitle()

    viewMode: (mode) -> @send 'viewMode', mode
    unfreeze: ->
      @freeze = false
      @send 'unfreezed'

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
