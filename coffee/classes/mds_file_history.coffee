{app} = require 'electron'
fs    = require 'fs'

class MdsFileHistory
  history: []
  max: 8

  instance = undefined

  constructor: ->
    return instance if instance?

    instance = @
    instance.loadFromConf()
    instance.filterExistance()

  generateMenuItemTemplate: (MdsWindow) =>
    menuitems = []

    if @history?.length > 0
      for full_path, idx in @history
        item = do (full_path) ->
          click: (item, w) -> MdsWindow.loadFromFile full_path, w?.mdsWindow

        if process.platform == 'darwin'
          item.label = full_path.replace(/\\/g, '/').replace(/.*\//, '')
        else
          item.label = "#{if idx < 9 then '&' else ''}#{idx + 1}: #{full_path}"

        menuitems.push item

    menuitems

  loadFromConf: =>
    if global?.marp?.config?
      @history = global.marp.config.get('fileHistory')
      @max = global.marp.config.get('fileHistoryMax')

  saveToConf: =>
    if global?.marp?.config?
      global.marp.config.set('fileHistory', @history)
      global.marp.config.set('fileHistoryMax', @max)
      global.marp.config.save()

  push: (path) =>
    dupHistory = []
    dupHistory.push p for p in @history when path != p
    @setHistory [path].concat(dupHistory) if @checkExistance(path)

  clear: =>
    @setHistory []

  filterExistance: =>
    newHistory = []
    newHistory.push path for path in @history when @checkExistance path
    @setHistory newHistory

  checkExistance: (filePath) =>
    try
      fs.accessSync(filePath, fs.F_OK)
      return true
    catch
      return false

  setHistory: (newHistory) =>
    @history = newHistory.slice 0, @max

    osRecentDocument = @history.slice(0)
    osRecentDocument.reverse() if process.platform == 'win32'

    app.clearRecentDocuments()
    app.addRecentDocument(path) for path in osRecentDocument

    @saveToConf()

module.exports = new MdsFileHistory
