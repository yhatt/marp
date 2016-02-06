ipc = require('electron').ipcRenderer

module.exports = class MdsRenderer
  id: null
  _accepted: false
  events: {}

  constructor: ->
    @id = parseInt window.location.hash.replace(/^#/, '')

    ipc.on 'MdsManagerRendererAccepted', (e, @_accepted) =>
    ipc.on 'MdsManagerSendEvent', @recievedEvent

  requestAccept: =>
    ipc.send 'MdsRendererRequestAccept', @id

  isAccepted: => !!@_accepted

  on: (evt, func) =>
    @events[evt] = [] unless @events[evt]?
    @events[evt].push func

  sendToMain:       (evt, args...) => @send evt, null, args...
  sendToAll:        (evt, args...) => @send evt, '*',  args...
  sendToAllWithMe:  (evt, args...) => @send evt, '**', args...
  send: (evt, ids = null, args...) =>
    ipc.send 'MdsRendererSendEvent', evt, { from: @id, to: ids }, args

  recievedEvent: (e, evt, target, args) =>
    @_call_event evt, args...

  _call_event: (evt, args...) =>
    funcs = @events[evt]
    return false unless funcs?

    func.apply(@, args) for func in funcs
    return true
