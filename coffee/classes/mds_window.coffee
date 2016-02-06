clsMdsManager  = require './mds_manager'
BrowserWindow  = require 'browser-window'
extend         = require 'extend'
MdsManager     = new clsMdsManager

module.exports = class MdsWindow
  browserWindow: null

  constructor: (options) ->
    @browserWindow = do =>
      bw = new BrowserWindow extend({}, options)
      @_window_id = bw.id

      bw.loadUrl "file://#{__dirname}/../../index.html##{@_window_id}"
      bw.on 'closed', =>
        @browserWindow = null
        @_setIsOpen false

    @_setIsOpen true

  trigger: (evt, args...) => @events[evt]?.apply(@, args)

  events: {}

  isOpen: => @_isOpen
  _setIsOpen: (state) =>
    @_isOpen = !!state

    if @_isOpen
      MdsManager.addWindow @_window_id, @
    else
      MdsManager.removeWindow @_window_id

    return @_isOpen
