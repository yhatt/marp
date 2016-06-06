{BrowserWindow, dialog} = require 'electron'

MdsManager     = require './mds_manager'
MdsMenu        = require './mds_menu'
MdsFileHistory = require './mds_file_history'
extend         = require 'extend'
fs             = require 'fs'
jschardet      = require 'jschardet'
iconv_lite     = require 'iconv-lite'
Path           = require 'path'

module.exports = class MdsWindow
  @appWillQuit: false

  @defOptions: () ->
    title:  'Marp'
    show:   false
    x:      global.marp.config.get 'windowPosition.x'
    y:      global.marp.config.get 'windowPosition.y'
    width:  global.marp.config.get 'windowPosition.width'
    height: global.marp.config.get 'windowPosition.height'
    icon:   Path.join(__dirname, '/../../images/marp.png')

  browserWindow: null
  path: null
  changed: false
  freeze: false

  _closeConfirmed: false

  constructor: (fileOpts = {}, @options = {}) ->
    @path = fileOpts?.path || null

    @browserWindow = do =>
      bw = new BrowserWindow extend(true, @constructor.defOptions(), @options)
      @_window_id = bw.id

      bw.maximize() if global.marp.config.get 'windowPosition.maximized'

      bw.loadURL "file://#{__dirname}/../../index.html##{@_window_id}"

      bw.webContents.on 'did-finish-load', =>
        @_windowLoaded = true
        @send 'setSplitter', global.marp.config.get('splitterPosition')
        @trigger 'load', fileOpts?.buffer || '', @path
        bw.show()

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
            title: 'Marp'
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

      updateWindowPosition = (e) =>
        unless global.marp.config.set('windowPosition.maximized', bw.isMaximized())
          global.marp.config.merge { windowPosition: bw.getBounds() }

      bw.on 'move', updateWindowPosition
      bw.on 'resize', updateWindowPosition
      bw.on 'maximize', updateWindowPosition
      bw.on 'unmaximize', updateWindowPosition

      bw.mdsWindow = @
      bw

    @_setIsOpen true

  @loadFromFile: (fname, mdsWindow, ignoreRecent = false) ->
    fs.readFile fname, (err, txt) =>
      return if err

      {encoding} = jschardet.detect(txt) ? {}
      if encoding isnt 'UTF-8' && encoding isnt 'ascii' && iconv_lite.encodingExists(encoding)
        buf = iconv_lite.decode(txt, encoding)
      else
        buf = txt.toString()

      unless ignoreRecent
        MdsFileHistory.push fname
        global.marp.mainMenu.setAppMenu()

      if mdsWindow? and mdsWindow.isBufferEmpty()
        mdsWindow.trigger 'load', buf, fname
      else
        new MdsWindow { path: fname, buffer: buf }

  loadFromFile: (fname, ignoreRecent = false) => MdsWindow.loadFromFile fname, @, ignoreRecent

  trigger: (evt, args...) =>
    @events[evt]?.apply(@, args)

  events:
    previewInitialized: ->
      @trigger 'viewMode', global.marp.config.get('viewMode')

    setConfig: (name, value, isSave = true) ->
      global.marp.config.set name, value
      global.marp.config.save() if isSave

    load: (buffer = '', path = null) ->
      @trigger 'initializeState', path
      @send 'loadText', buffer

    loadFromFile: (fname) -> @loadFromFile fname

    save: (triggerOnSucceeded = null) ->
      if @path then @send('save', @path, triggerOnSucceeded) else @trigger('saveAs', triggerOnSucceeded)

    saveAs: (triggerOnSucceeded = null) ->
      dialog.showSaveDialog @browserWindow,
        title: 'Save as...'
        filters: [{ name: 'Markdown file', extensions: ['md'] }]
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

      dirs = if filePath then [Path.dirname(filePath)] else []
      @send 'setImageDirectories', dirs

    setChangedStatus: (changed) ->
      @changed = !!changed
      @refreshTitle()

    viewMode: (mode) ->
      global.marp.config.set('viewMode', mode)
      global.marp.config.save()

      @send 'viewMode', mode

    unfreeze: ->
      @freeze = false
      @send 'unfreezed'

  refreshTitle: =>
    if process.platform == 'darwin'
      @browserWindow?.setTitle "#{@getShortPath()}#{if @changed then ' *' else ''}"
      @browserWindow?.setRepresentedFilename @path || ''
      @browserWindow?.setDocumentEdited @changed
    else
      @browserWindow?.setTitle "#{@options?.title || 'Marp'} - #{@getShortPath()}#{if @changed then ' *' else ''}"

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

  isBufferEmpty: => !@path and not @changed

  send: (evt, args...) =>
    return false unless @_windowLoaded and @browserWindow?
    @browserWindow.webContents.send 'MdsManagerSendEvent', evt, { from: null, to: @_window_id }, args
