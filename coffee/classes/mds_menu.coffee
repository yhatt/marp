electron = require('electron')
Menu     = electron.Menu || electron.remote.Menu
MenuItem = electron.MenuItem || electron.remote.MenuItem
isRemote = !electron.Menu?

module.exports = class MdsMenu
  @appMenu: null
  menu: new Menu()

  constructor: (@template) ->

  @filterTemplate: (tpl, opts = {}) =>
    newTpl = []
    for item in tpl
      filtered = false

      # Platform filter
      if item.platform?
        target_platforms = item.platform.split(",")
        current_platform = process.platform.toLowerCase()

        for target_platform in target_platforms
          invert_condition = false

          if target_platform[0] == '!'
            target_platform  = target_platform.slice 1
            invert_condition = true

          cond = target_platform == current_platform
          cond = !cond if invert_condition

          unless cond
            filtered = true
            break

      # Replacement filter
      if item.replacement?
        filtered = true
        if opts?.replacements? and opts.replacements[item.replacement]?
          Array.prototype.push.apply(newTpl, MdsMenu.filterTemplate(opts.replacements[item.replacement], opts))

      unless filtered
        newTplIdx = newTpl.push(item) - 1

        if newTpl[newTplIdx].submenu?
          newTpl[newTplIdx].submenu = MdsMenu.filterTemplate(newTpl[newTplIdx].submenu, opts)

    return newTpl

  getMenu: (opts = {}) =>
    if @template?
      @menu = Menu.buildFromTemplate(MdsMenu.filterTemplate(@template, opts))
    else
      @menu = new Menu()

  setAppMenu: (opts = {}) =>
    if !isRemote
      MdsMenu.appMenu = @
      Menu.setApplicationMenu MdsMenu.appMenu.getMenu(opts)

  popup: (opts = {}) =>
    @getMenu(opts).popup(electron.remote.getCurrentWindow()) if isRemote
