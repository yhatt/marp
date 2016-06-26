{app, dialog, shell}  = require 'electron'
extend                = require 'extend'
path                  = require 'path'
MdsMenu               = require './mds_menu'
MdsFileHistory        = require './mds_file_history'

module.exports = class MdsMainMenu
  states: {}
  window: null
  menu: null

  @useAppMenu: process.platform is 'darwin'
  @instances: new Map
  @currentMenuId: null

  constructor: (@states) ->
    @mdsWindow = require './mds_window'
    @window    = @states?.window || null
    @window_id = @window?.id || null

    MdsMainMenu.instances.set @window_id, @
    @listenWindow()
    @updateMenu()

  listenWindow: () =>
    return false unless @window?

    resetAppMenu = ->
      MdsMainMenu.currentMenuId = null
      MdsMainMenu.instances.get(null).applyMenu() if MdsMainMenu.useAppMenu

    @window.on 'focus', =>
      MdsMainMenu.currentMenuId = @window_id
      @applyMenu() if MdsMainMenu.useAppMenu

    @window.on 'blur', resetAppMenu

    @window.on 'closed', =>
      MdsMainMenu.instances.delete(@window_id)
      resetAppMenu()

  applyMenu: () =>
    if MdsMainMenu.useAppMenu
      if @window_id == MdsMainMenu.currentMenuId
        @menu.object.setAppMenu(@menu.options)
    else
      @menu.object.setMenu(@window, @menu.options) if @window?

  @updateMenuToAll: () =>
    @instances.forEach (m) -> m.updateMenu()

  updateMenu: () =>
    MdsWindow = @mdsWindow
    @menu =
      object: new MdsMenu [
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
            { label: 'Quit', role: 'quit' }
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
            { label: '&Save', enabled: @window?, accelerator: 'CmdOrCtrl+S', click: => @window.mdsWindow.trigger 'save' }
            { label: 'Save &As...', enabled: @window?, click: => @window.mdsWindow.trigger 'saveAs' }
            { type: 'separator' }
            { label: '&Export Slides as PDF...', enabled: @window?, accelerator: 'CmdOrCtrl+Shift+E', click: => @window.mdsWindow.trigger 'exportPdfDialog' }
            { type: 'separator', platform: '!darwin' }
            { label: 'Close', role: 'close', platform: '!darwin' }
          ]
        }
        {
          label: '&Edit'
          submenu: [
            {
              label: '&Undo'
              enabled: @window?
              accelerator: 'CmdOrCtrl+Z'
              click: => @window.mdsWindow.send 'editCommand', 'undo' unless @window.mdsWindow.freeze
            }
            {
              label: '&Redo'
              enabled: @window?
              accelerator: 'Shift+CmdOrCtrl+Z'
              click: => @window.mdsWindow.send 'editCommand', 'redo' unless @window.mdsWindow.freeze
            }
            { type: 'separator' }
            { label: 'Cu&t', accelerator: 'CmdOrCtrl+X', role: 'cut' }
            { label: '&Copy', accelerator: 'CmdOrCtrl+C', role: 'copy' }
            { label: '&Paste', accelerator: 'CmdOrCtrl+V', role: 'paste' }
            { label: '&Delete', role: 'delete' }
            {
              label: 'Select &All'
              enabled: @window?
              accelerator: 'CmdOrCtrl+A'
              click: => @window.mdsWindow.send 'editCommand', 'selectAll' unless @window.mdsWindow.freeze
            }
          ]
        }
        {
          label: '&View'
          submenu: [
            {
              label: '&Preview Style'
              enabled: @window?
              submenu: [{ replacement: 'slideViews' }]
            }
            {
              label: '&Theme'
              enabled: @window?
              submenu: [{ replacement: 'themes' }]
            }
            { type: 'separator' }
            {
              label: 'Toggle &Full Screen'
              accelerator: do -> if process.platform == 'darwin' then 'Ctrl+Command+F' else 'F11'
              role: 'togglefullscreen'
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
        {
          label: '&Dev'
          visible: @states.development? and !!@states.development
          submenu: [
            { label: 'Toggle &Dev Tools', enabled: @window?, accelerator: 'Alt+Ctrl+I', click: => @window.toggleDevTools() }
            { label: 'Toggle &Markdown Dev Tools', enabled: @window?, accelerator: 'Alt+Ctrl+Shift+I', click: => @window.mdsWindow.send 'openDevTool' }
          ]
        }
      ]

      options:
        replacements:
          fileHistory: do =>
            historyMenu = MdsFileHistory.generateMenuItemTemplate(MdsWindow)
            historyMenu.push { type: 'separator' } if historyMenu.length > 0
            historyMenu.push
              label: '&Clear Menu'
              enabled: historyMenu.length > 0
              click: =>
                MdsFileHistory.clear()
                MdsMainMenu.updateMenuToAll()
                @applyMenu()

            return historyMenu

          slideViews: [
            {
              label: '&Markdown'
              enabled: @window?
              type: if @window? then 'radio' else 'normal'
              checked: @states.viewMode == 'markdown'
              click: => @window.mdsWindow.trigger 'viewMode', 'markdown'
            }
            {
              label: '1:1 &Slide'
              enabled: @window?
              type: if @window? then 'radio' else 'normal'
              checked: @states.viewMode == 'screen'
              click: => @window.mdsWindow.trigger 'viewMode', 'screen'
            }
            {
              label: 'Slide &List'
              enabled: @window?
              type: if @window? then 'radio' else 'normal'
              checked: @states.viewMode == 'list'
              click: => @window.mdsWindow.trigger 'viewMode', 'list'
            }
          ]

          themes: [
            {
              label: '&Default'
              enabled: @window?
              type: if @window? then 'radio' else 'normal'
              checked: !@states?.theme || @states.theme == 'default'
              click: => @window.mdsWindow.send 'setTheme', 'default' unless @window.mdsWindow.freeze
            }
            {
              label: '&Gaia'
              enabled: @window?
              type: if @window? then 'radio' else 'normal'
              checked: @states.theme == 'gaia'
              click: => @window.mdsWindow.send 'setTheme', 'gaia' unless @window.mdsWindow.freeze
            }
          ]

    @applyMenu()
