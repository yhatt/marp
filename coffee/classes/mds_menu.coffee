electron = require('electron')
Menu     = electron.Menu || electron.remote.Menu
MenuItem = electron.MenuItem || electron.remote.MenuItem
isRemote = !electron.Menu?

module.exports = class MdsMenu
  @appMenu: null
  menu: new Menu()

  @isOSX: ->
    process?.platform == 'darwin'

  constructor: (template, osxTemplate) ->
    if template?
      if !isRemote and osxTemplate? and @constructor.isOSX()
        template.unshift
          label: electron.app.getName()
          submenu: osxTemplate

      @menu = Menu.buildFromTemplate(template)

  setAppMenu: =>
    if !isRemote
      MdsMenu.appMenu = @
      Menu.setApplicationMenu MdsMenu.appMenu.menu

  popup: =>
    @menu.popup(electron.remote.getCurrentWindow()) if isRemote
