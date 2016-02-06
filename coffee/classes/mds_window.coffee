ManagerClass   = require './mds_manager'
BrowserWindow  = require 'browser-window'
extend         = require 'extend'
MdsManager     = new ManagerClass

module.exports = class MdsWindow
  browserWindow: null
  events: {}

  constructor: (options) ->
    @browserWindow = do =>
      bw = new BrowserWindow extend({}, options)
      @_window_id = bw.id

      bw.loadUrl "file://#{__dirname}/../../index.html##{@_window_id}"
      bw.on 'closed', =>
        @browserWindow = null
        @setOpening false

    @setOpening true

  getOpening: => @_opening

  setOpening: (state) =>
    @_opening = !!state

    if @_opening
      MdsManager.addWindow @_window_id, @
    else
      MdsManager.removeWindow @_window_id

    return @_opening

  _fire_manager_event: (evt, args...) => @events[evt]?.apply(@, args)
