app       = require 'app'
MdsWindow = require './classes/mds_window'
MdsMenu   = require './classes/mds_menu'

require('crash-reporter').start()

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
        click: (item, w) -> w.mdsWindow.trigger 'open' if w
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
        label: 'Export to slide PDF...'
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
        role: 'undo'
      }
      {
        label: 'Redo'
        accelerator: 'Shift+CmdOrCtrl+Z'
        role: 'redo'
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
        role: 'selectall'
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
        click: (item, focusedWindow) ->
          focusedWindow.setFullScreen !focusedWindow.isFullScreen() if focusedWindow
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
  app.quit() if process.platform != 'darwin'

app.on 'ready', ->
  appMenu.setAppMenu()
  new MdsWindow
