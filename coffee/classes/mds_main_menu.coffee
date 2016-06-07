{app, dialog, shell}  = require 'electron'
extend                = require 'extend'
path                  = require 'path'
MdsMenu               = require './mds_menu'
MdsWindow             = require './mds_window'
MdsFileHistory        = require './mds_file_history'

module.exports = class MdsMainMenu
  opts: {}
  menu: null

  constructor: (@opts) ->

  setAppMenu: (menuOptsOriginal = {}) =>
    menuOpts = extend true, menuOptsOriginal,
      replacements:
        fileHistory: do =>
          historyMenu = MdsFileHistory.generateMenuItemTemplate(MdsWindow)
          historyMenu.push { type: 'separator' } if historyMenu.length > 0
          historyMenu.push
            label: '&Clear Menu'
            enabled: historyMenu.length > 0
            click: (item, w) =>
              MdsFileHistory.clear()
              global.marp.mainMenu.setAppMenu()

          return historyMenu

        # TODO: Radio type menu is not implemented. Currently main menu is not supported per window states.
        slideViews: [
          {
            label: '&Markdown view'
            #type: 'radio'
            #checked: global.marp.config.get('viewMode') == 'markdown'
            click: (item, w) -> w.mdsWindow.trigger 'viewMode', 'markdown' if w
          }
          {
            label: '1:1 &Slide view'
            #type: 'radio'
            #checked: global.marp.config.get('viewMode') == 'screen'
            click: (item, w) -> w.mdsWindow.trigger 'viewMode', 'screen' if w
          }
          {
            label: 'Slide &List view'
            #type: 'radio'
            #checked: global.marp.config.get('viewMode') == 'list'
            click: (item, w) -> w.mdsWindow.trigger 'viewMode', 'list' if w
          }
        ]

    @getMenu(menuOpts).setAppMenu(menuOpts)

  getMenu: (additionalOpts = {}) =>
    @menu = new MdsMenu @generateTemplate(extend(@opts, additionalOpts))

  generateTemplate: (opts = @opts) =>
    menuTpl = [
      {
        label: app.getName()
        platform: 'darwin'
        submenu: [
          { label: 'About', role: 'about' }
          { type: 'separator' }
          { label: 'Services', role: 'services', submenu: [] }
          { type: 'separator' }
          { label: 'Hide', accelerator: 'Command+H', role: 'hide' }
          { label: 'Hide Others', accelerator: 'Command+Alt+H', role: 'hideothers' }
          { label: 'Show All', role: 'unhide' }
          { type: 'separator' }
          { label: 'Quit', accelerator: 'Command+Q', click: -> app.quit() }
        ]
      }
      {
        label: '&File'
        submenu: [
          { label: '&New file', accelerator: 'CmdOrCtrl+N', click: -> new MdsWindow }
          { type: 'separator' }
          {
            label: '&Open...'
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
            label: 'Open &Recent'
            submenu: [{ replacement: 'fileHistory' }]
          }
          { label: '&Save', accelerator: 'CmdOrCtrl+S', click: (item, w) -> w.mdsWindow.trigger 'save' if w }
          { label: 'Save &As...', click: (item, w) -> w.mdsWindow.trigger 'saveAs' if w }
          { type: 'separator' }
          { label: '&Export Slides as PDF...', accelerator: 'CmdOrCtrl+Shift+E', click: (item, w) -> w.mdsWindow.trigger 'exportPdfDialog' if w }
          { type: 'separator', platform: '!darwin' }
          { label: 'Close', role: 'close', platform: '!darwin' }
        ]
      }
      {
        label: '&Edit'
        submenu: [
          { label: '&Undo', accelerator: 'CmdOrCtrl+Z', click: (item, w) -> w.mdsWindow.send 'editCommand', 'undo' if w and !w.mdsWindow.freeze }
          { label: '&Redo', accelerator: 'Shift+CmdOrCtrl+Z', click: (item, w) -> w.mdsWindow.send 'editCommand', 'redo' if w and !w.mdsWindow.freeze }
          { type: 'separator' }
          { label: 'Cu&t', accelerator: 'CmdOrCtrl+X', role: 'cut' }
          { label: '&Copy', accelerator: 'CmdOrCtrl+C', role: 'copy' }
          { label: '&Paste', accelerator: 'CmdOrCtrl+V', role: 'paste' }
          { label: 'Select &All', accelerator: 'CmdOrCtrl+A', click: (item, w) -> w.mdsWindow.send 'editCommand', 'selectAll' if w and !w.mdsWindow.freeze }
        ]
      }
      {
        label: '&View'
        submenu: [
          { replacement: 'slideViews' }
          { type: 'separator' }
          {
            label: 'Toggle &Full Screen'
            accelerator: do -> if process.platform == 'darwin' then 'Ctrl+Command+F' else 'F11'
            click: (item, w) -> w.setFullScreen !w.isFullScreen() if w
          }
        ]
      }
      {
        label: 'Window'
        role: 'window'
        platform: 'darwin'
        submenu: [
          { label: 'Minimize', accelerator: 'CmdOrCtrl+M', role: 'minimize' }
          { label: 'Close', accelerator: 'CmdOrCtrl+W', role: 'close' }
          { type: 'separator' }
          { label: 'Bring All to Front', role: 'front' }
        ]
      }
      {
        label: '&Help'
        role: 'help'
        submenu: [
          { label: 'Visit Marp &Website', click: -> shell.openExternal('https://yhatt.github.io/marp/') }
          { label: '&Release Notes', click: -> shell.openExternal('https://github.com/yhatt/marp/releases') }
          { type: 'separator' }
          {
            label: 'Open &Examples'
            submenu: [
              {
                label: '&Marp basic example',
                click: (item, w) ->
                  MdsWindow.loadFromFile(
                    path.join(__dirname, '../../example.md'),
                    w?.mdsWindow, true
                  )
              }
              { type: 'separator' }
              {
                label: '&Gaia theme',
                click: (item, w) ->
                  MdsWindow.loadFromFile(
                    path.join(__dirname, '../../examples/gaia.md'),
                    w?.mdsWindow, true
                  )
              }
            ]
          }
        ]
      }
    ]

    if opts.development? and !!opts.development
      menuTpl.push
        label: '&Dev'
        submenu: [
          { label: 'Toggle &Dev Tools', accelerator: 'Alt+Ctrl+I', click: (item, w) -> w.toggleDevTools() if w }
          { label: 'Toggle &Markdown Dev Tools', accelerator: 'Alt+Ctrl+Shift+I', click: (item, w) -> w.mdsWindow.send 'openDevTool' if w }
        ]

    return menuTpl
