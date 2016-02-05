app = require 'app'
BrowserWindow = require 'browser-window'

require('crash-reporter').start()

main_window = null

app.on 'window-all-closed', () ->
  app.quit() if process.platform != 'darwin'

app.on 'ready', () ->
  main_window = new BrowserWindow
    width: 800
    height: 300

  main_window.loadUrl "file://#{__dirname}/../index.html"

  main_window.on 'closed', () ->
    main_window = null
