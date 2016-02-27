app    = require('electron').app
fs     = require 'fs'
Path   = require 'path'
extend = require 'extend'

class MdsConfig
  instance = undefined

  config: {}
  configFile: Path.join(app.getPath('userData'), 'config.json')

  @initialConfig:
    fileHistory: []
    fileHistoryMax: 8
    splitterPosition: 0.5
    viewMode: 'screen'

  constructor: ->
    return instance if instance?

    instance = @
    instance.initialize()

  initialize: (conf = @configFile) => @load(conf, true)

  load: (conf = @configFile, initialize = false) =>
    try
      fs.accessSync(conf, fs.F_OK)
      @config = extend(true, MdsConfig.initialConfig, JSON.parse(fs.readFileSync(conf).toString()))
    catch
      if initialize
        console.log 'Failed reading config file. Config initialized.'
        @config = MdsConfig.initialConfig
        @save()

  save: (json = @config) =>
    try
      fs.writeFileSync(@configFile, JSON.stringify(json))
      return json
    catch
      return {}

  get: (name, _target = @config) =>
    names = name.split '.'
    return null unless _target[names[0]]?
    return @get(names.slice(1).join('.'), _target[names[0]]) if names.length > 1
    _target[names[0]]

  set: (name, val) =>
    names = name.split '.'
    obj   = {}
    elm   = obj

    for key, i in names
      elm[key] = if i == names.length - 1 then val else {}
      elm = elm[key]

    @merge obj

  merge: (object) => @config = extend(@config, object)

module.exports = new MdsConfig
