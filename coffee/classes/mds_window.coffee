{BrowserWindow, dialog} = require 'electron'

MdsManager     = require './mds_manager'
MdsMenu        = require './mds_menu'
MdsMainMenu    = require './mds_main_menu'
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
  resourceState: null

  _closeConfirmed: false
  _watchingResources: new Set

  viewMode: null

  constructor: (fileOpts = {}, @options = {}) ->
    @path = fileOpts?.path || null
    @viewMode = global.marp.config.get('viewMode')

    @browserWindow = do =>
      bw = new BrowserWindow extend(true, {}, MdsWindow.defOptions(), @options)
      @_window_id = bw.id

      loadCmp = (details) =>
        setTimeout =>
          @_watchingResources.delete(details.id)
          @updateResourceState()
        , 500

      bw.webContents.session.webRequest.onCompleted loadCmp
      bw.webContents.session.webRequest.onErrorOccurred loadCmp
      bw.webContents.session.webRequest.onBeforeRequest (details, callback) =>
        @_watchingResources.add(details.id)
        @updateResourceState()
        callback({})

      @menu = new MdsMainMenu
        window: bw
        development: global.marp.development
        viewMode: @viewMode

      bw.maximize() if global.marp.config.get 'windowPosition.maximized'

      bw.loadURL "file://#{__dirname}/../../index.html##{@_window_id}"

      bw.webContents.on 'did-finish-load', =>
        @_windowLoaded = true
        @send 'setSplitter', global.marp.config.get('splitterPosition')
        @send 'setEditorConfig', global.marp.config.get('editor')
        @trigger 'load', fileOpts?.buffer || '', @path

      bw.once 'ready-to-show', => bw.show()

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
            cancelId: 2
          , (result) =>
            # Wrap by setTimeout to avoid app termination unexpectedly on Linux.
            switch result
              when 0 then setTimeout (=> @trigger 'save', 'forceClose'), 0
              when 1 then setTimeout (=> @trigger 'forceClose'), 0
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

  @loadFromFile: (fname, mdsWindow, options = {}) ->
    fs.readFile fname, (err, txt) =>
      return if err

      encoding = options?.encoding || jschardet.detect(txt)?.encoding
      buf = if encoding isnt 'UTF-8' and encoding isnt 'ascii' and iconv_lite.encodingExists(encoding)
        iconv_lite.decode(txt, encoding)
      else
        txt.toString()

      unless options?.ignoreRecent
        MdsFileHistory.push fname
        MdsMainMenu.updateMenuToAll()

      if mdsWindow? and (options?.override or mdsWindow.isBufferEmpty())
        mdsWindow.trigger 'load', buf, fname
      else
        new MdsWindow { path: fname, buffer: buf }

  loadFromFile: (fname, options = {}) => MdsWindow.loadFromFile fname, @, options

  trigger: (evt, args...) =>
    @events[evt]?.apply(@, args)

  events:
    previewInitialized: ->
      @trigger 'viewMode', @viewMode

    setConfig: (name, value, isSave = true) ->
      global.marp.config.set name, value
      global.marp.config.save() if isSave

    load: (buffer = '', path = null) ->
      @trigger 'initializeState', path
      @send 'loadText', buffer

    loadFromFile: (fname, options = {}) -> @loadFromFile fname, options

    reopen: (options = {}) ->
      return if @freeze or !@path
      return if @changed and dialog.showMessageBox(@browserWindow,
        type: 'question'
        buttons: ['OK', 'Cancel']
        title: 'Marp'
        message: 'Are you sure?'
        detail: 'You will lose your changes on Marp. Reopen anyway?')

      @loadFromFile @path, extend({ override: true }, options)

    save: (triggers = {}) ->
      if @path then @send('save', @path, triggers) else @trigger('saveAs', triggers)

    saveAs: (triggers = {}) ->
      dialog.showSaveDialog @browserWindow,
        title: 'Save as...'
        filters: [{ name: 'Markdown file', extensions: ['md'] }]
      , (fname) =>
        if fname?
          @send 'save', fname, triggers
        else
          MdsWindow.appWillQuit = false

    writeFile: (fileName, data, triggers = {}) ->
      fs.writeFile fileName, data, (err) =>
        unless err
          console.log "Write file to #{fileName}."
          @trigger triggers.succeeded if triggers.succeeded?
        else
          console.log err
          dialog.showMessageBox @browserWindow,
            type: 'error'
            buttons: ['OK']
            title: 'Marp'
            message: "Marp cannot write the file to #{fileName}."
            detail: err.toString()

          MdsWindow.appWillQuit = false
          @trigger triggers.failed, err if triggers.failed?

        @trigger triggers.finalized if triggers.finalized?

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
      @trigger 'setChangedStatus', changed

      dir = if filePath then "#{Path.dirname(filePath)}#{Path.sep}" else null
      @send 'setImageDirectory', dir

      @menu.updateMenu()

    setChangedStatus: (changed) ->
      @changed = !!changed
      @refreshTitle()

    viewMode: (mode) ->
      global.marp.config.set('viewMode', mode)
      global.marp.config.save()

      @send 'viewMode', mode

      @menu.states.viewMode = mode
      @menu.updateMenu()

    themeChanged: (theme) ->
      @menu.states.theme = theme
      @menu.updateMenu()

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

  updateResourceState: =>
    newState = if @_watchingResources.size <= 0 then 'loaded' else 'loading'
    @send 'resourceState', newState if @resourceState isnt newState

    @resourceState = newState

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
