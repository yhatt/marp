global.marp or=
  config: require './classes/mds_config'

{app}     = require 'electron'
Path      = require 'path'
MdsWindow = require './classes/mds_window'
MainMenu  = require './classes/mds_main_menu'
{exist}   = require './classes/mds_file'

# Initialize config
global.marp.config.initialize()

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
      if exist(resolved_file = Path.resolve(arg))
        opts.file = resolved_file
        break_arg = true

  break if break_arg

# Main menu
global.marp.mainMenu = new MainMenu opts

# Application events
app.on 'window-all-closed', ->
  if process.platform != 'darwin' or !!MdsWindow.appWillQuit
    global.marp.config.save()
    app.quit()

app.on 'before-quit', ->
  MdsWindow.appWillQuit = true

app.on 'activate', (e, hasVisibleWindows) ->
  new MdsWindow unless hasVisibleWindows

app.on 'open-file', (e, path) ->
  e.preventDefault()

  opts.fileOpened = true
  MdsWindow.loadFromFile path, null

app.on 'ready', ->
  global.marp.mainMenu.setAppMenu()

  unless opts.fileOpened
    if opts.file
      MdsWindow.loadFromFile opts.file, null
    else
      new MdsWindow
