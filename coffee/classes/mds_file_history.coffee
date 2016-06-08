{app}   = require 'electron'
{exist} = require './mds_file'

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
      global.marp.config.set('fileHistory', @history, true)
      global.marp.config.set('fileHistoryMax', @max)
      global.marp.config.save()

  push: (path) =>
    dupHistory = []
    dupHistory.push p for p in @history when path != p
    @setHistory [path].concat(dupHistory) if exist(path)

  clear: =>
    @setHistory []

  filterExistance: =>
    newHistory = []
    newHistory.push path for path in @history when exist(path)
    @setHistory newHistory

  setHistory: (newHistory) =>
    @history = newHistory.slice 0, @max

    osRecentDocument = @history.slice(0)
    osRecentDocument.reverse() if process.platform == 'win32'

    app.clearRecentDocuments()
    app.addRecentDocument(path) for path in osRecentDocument

    @saveToConf()

module.exports = new MdsFileHistory
