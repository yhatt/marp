app       = require 'app'
fs        = require 'fs'
dialog    = require('electron').dialog
MdsWindow = require './classes/mds_window'
MdsMenu   = require './classes/mds_menu'
Path      = require 'path'

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
appMenuTpl = [
  {
    label: 'File'
    submenu: [
      {
        label: 'New file'
        accelerator: 'CmdOrCtrl+N'
        click: -> new MdsWindow
      }
      { type: 'separator' }
      {
        label: 'Open...'
        accelerator: 'CmdOrCtrl+O'
        click: (item, w) ->
          args = [
            {
              title: 'Open'
              filters: [
                { name: 'Markdown files', extensions: ['md', 'mdown'] }
                { name: 'Text file', extensions: ['txt'] }
                { name: 'All files', extensions: ['*'] }
              ]
              properties: ['openFile', 'createDirectory']
            }
            (fnames) ->
              return unless fnames?
              MdsWindow.loadFromFile fnames[0], w?.mdsWindow
          ]
          args.unshift w.mdsWindow.browserWindow if w?.mdsWindow?.browserWindow?
          dialog.showOpenDialog.apply @, args
      }
      {
        label: 'Save'
        accelerator: 'CmdOrCtrl+S'
        click: (item, w) -> w.mdsWindow.trigger 'save' if w
      }
      {
        label: 'Save as...'
        click: (item, w) -> w.mdsWindow.trigger 'saveAs' if w
      }
      { type: 'separator' }
      {
        label: 'Export slides to PDF...'
        accelerator: 'CmdOrCtrl+Shift+E'
        click: (item, w) -> w.mdsWindow.trigger 'exportPdfDialog' if w
      }
    ]
  }
  {
    label: 'Edit'
    submenu: [
      {
        label: 'Undo'
        accelerator: 'CmdOrCtrl+Z'
        click: (item, w) -> w.mdsWindow.send 'editCommand', 'undo' if w
      }
      {
        label: 'Redo'
        accelerator: 'Shift+CmdOrCtrl+Z'
        click: (item, w) -> w.mdsWindow.send 'editCommand', 'redo' if w
      }
      { type: 'separator' }
      {
        label: 'Cut'
        accelerator: 'CmdOrCtrl+X'
        role: 'cut'
      }
      {
        label: 'Copy'
        accelerator: 'CmdOrCtrl+C'
        role: 'copy'
      }
      {
        label: 'Paste'
        accelerator: 'CmdOrCtrl+V'
        role: 'paste'
      }
      {
        label: 'Select All'
        accelerator: 'CmdOrCtrl+A'
        click: (item, w) -> w.mdsWindow.send 'editCommand', 'selectAll' if w
      }
    ]
  }
  {
    label: 'View'
    submenu: [
      {
        label: 'Markdown view'
        click: (item, w) -> w.mdsWindow.trigger 'viewMode', 'markdown' if w
      }
      {
        label: '1:1 slide view'
        click: (item, w) -> w.mdsWindow.trigger 'viewMode', 'screen' if w
      }
      {
        label: 'Slide list view'
        click: (item, w) -> w.mdsWindow.trigger 'viewMode', 'list' if w
      }
      { type: 'separator' }
      {
        label: 'Toggle Full Screen'
        accelerator: do -> if MdsMenu.isOSX() then 'Ctrl+Command+F' else 'F11'
        click: (item, w) ->
          w.setFullScreen !w.isFullScreen() if w
      }
    ]
  }
]

if MdsMenu.isOSX()
  appMenuTpl.push
    label: 'Window'
    role: 'window'
    submenu: [
      {
        label: 'Minimize'
        accelerator: 'CmdOrCtrl+M'
        role: 'minimize'
      }
      {
        label: 'Close'
        accelerator: 'CmdOrCtrl+W'
        role: 'close'
      }
      { type: 'separator' }
      {
        label: 'Bring All to Front'
        role: 'front'
      }
    ]
else
  appMenuTpl[0].submenu.push
    type: 'separator'
  appMenuTpl[0].submenu.push
    label: 'Close'
    role: 'close'

if opts.development
  appMenuTpl.push
    label: 'Dev'
    submenu: [
      {
        label: 'Toggle Dev Tools'
        accelerator: 'Alt+Ctrl+I'
        click: (item, w) -> w.toggleDevTools() if w
      }
      {
        label: 'Toggle Markdown Dev Tools'
        accelerator: 'Alt+Ctrl+Shift+I'
        click: (item, w) -> w.mdsWindow.send 'openDevTool' if w
      }
    ]

appMenu = new MdsMenu appMenuTpl, [
  {
    label: 'About'
    role: 'about'
  }
  {
    type: 'separator'
  }
  {
    label: 'Services'
    role: 'services'
    submenu: []
  }
  {
    type: 'separator'
  }
  {
    label: 'Hide'
    accelerator: 'Command+H'
    role: 'hide'
  }
  {
    label: 'Hide Others'
    accelerator: 'Command+Alt+H'
    role: 'hideothers'
  }
  {
    label: 'Show All'
    role: 'unhide'
  }
  {
    type: 'separator'
  }
  {
    label: 'Quit'
    accelerator: 'Command+Q'
    click: -> app.quit()
  }
]

app.on 'window-all-closed', ->
  app.quit() if process.platform != 'darwin' or !!MdsWindow.appWillQuit

app.on 'before-quit', ->
  MdsWindow.appWillQuit = true

app.on 'activate', (e, hasVisibleWindows) ->
  new MdsWindow unless hasVisibleWindows

app.on 'ready', ->
  appMenu.setAppMenu()

  if opts.file
    MdsWindow.loadFromFile opts.file, null
  else
    new MdsWindow
