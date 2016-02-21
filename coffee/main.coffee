app       = require 'app'
fs        = require 'fs'
Path      = require 'path'
MdsWindow = require './classes/mds_window'
MainMenu  = require './classes/mds_main_menu'

require('crash-reporter').start()

# Parse arguments
opts =
  file: null
  development: false

for arg in process.argv.slice(1)
  break_arg = false
  switch arg
    when '--development', '--dev'
      opts.development = true
    else
      resolved_file = Path.resolve(arg)

      try
        unless fs.accessSync(resolved_file, fs.R_OK)?
          if fs.lstatSync(resolved_file).isFile()
            opts.file = resolved_file
            break_arg = true

  break if break_arg

# Main menu
global.mdSlide =
  mainMenu: new MainMenu opts

# Application events
app.on 'window-all-closed', ->
  app.quit() if process.platform != 'darwin' or !!MdsWindow.appWillQuit

app.on 'before-quit', ->
  MdsWindow.appWillQuit = true

app.on 'activate', (e, hasVisibleWindows) ->
  new MdsWindow unless hasVisibleWindows

app.on 'open-file', (e, path) ->
  e.preventDefault()

  opts.fileOpened = true
  MdsWindow.loadFromFile path, null

app.on 'ready', ->
  global.mdSlide.mainMenu.setAppMenu()

  unless opts.fileOpened
    if opts.file
      MdsWindow.loadFromFile opts.file, null
    else
      new MdsWindow
