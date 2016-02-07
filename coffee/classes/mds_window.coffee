clsMdsManager  = require './mds_manager'
BrowserWindow  = require 'browser-window'
extend         = require 'extend'
fs             = require 'fs'
dialog         = require('electron').dialog
MdsManager     = new clsMdsManager

module.exports = class MdsWindow
  browserWindow: null

  constructor: (options) ->
    @browserWindow = do =>
      bw = new BrowserWindow extend({}, options)
      @_window_id = bw.id

      bw.loadUrl "file://#{__dirname}/../../index.html##{@_window_id}"

      bw.webContents.on 'did-finish-load', =>
        @_windowLoaded = true

      bw.on 'closed', =>
        @browserWindow = null
        @_setIsOpen false

    @_setIsOpen true

  trigger: (evt, args...) =>
    @events[evt]?.apply(@, args)

  events:
    exportPdfDialog: (target) ->
      dialog.showSaveDialog @browserWindow,
        title: 'Export to PDF...'
        filters: [{ name: 'PDF file', extensions: ['pdf'] }]
      , (fname) =>
        return unless fname?
        @send 'publishPdf', fname

    saveData: (fileName, data) ->
      fs.writeFile fileName, data, (err) ->
        console.log "Save data to #{fileName}." unless err

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
