app = require 'app'
MdsWindow = require './classes/mds_window'

require('crash-reporter').start()

app.on 'window-all-closed', ->
  app.quit() if process.platform != 'darwin'

app.on 'ready', ->
  new MdsWindow
