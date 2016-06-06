extend  = require 'extend'
path    = require 'path'
{exist} = require './mds_file'

module.exports = class MdsMdSetting
  @generalTransfomer:
    unit: (v) ->
      val = undefined

      if m = "#{v}".match(/^(\d+(?:\.\d+)?)((?:px|cm|mm|in|pt|pc)?)$/)
        val = parseFloat(m[1])

        if m[2] is 'cm'
          val = val * 960 / 25.4
        else if m[2] is 'mm'
          val = val * 96 / 25.4
        else if m[2] is 'in'
          val = val * 96
        else if m[2] is 'pt'
          val = val * 4 / 3
        else if m[2] is 'pc'
          val = val * 16

      Math.floor(val) || undefined

  @transformers:
    page_number: (v) -> v is 'true'
    width: MdsMdSetting.generalTransfomer.unit
    height: MdsMdSetting.generalTransfomer.unit
    theme: (v) ->
      basefile = "css/themes/#{path.basename(v)}.css"
      if exist(path.resolve(__dirname, "../../#{basefile}")) then basefile else null
    template: (v) -> v

  @findTransformer: (prop) =>
    for transformerProp, transformer of MdsMdSetting.transformers
      return transformer if prop is transformerProp
    null

  @duckTypes:
    size: (v) ->
      ret = {}
      cmd = "#{v}".toLowerCase()

      if cmd.startsWith('4:3')
        ret = { width: 1024, height: 768 }
      else if cmd.startsWith('16:9')
        ret = { width: 1366, height: 768 }
      else if cmd.startsWith('a0')
        ret = { width: '1189mm', height: '841mm' }
      else if cmd.startsWith('a1')
        ret = { width: '841mm', height: '594mm' }
      else if cmd.startsWith('a2')
        ret = { width: '594mm', height: '420mm' }
      else if cmd.startsWith('a3')
        ret = { width: '420mm', height: '297mm' }
      else if cmd.startsWith('a4')
        ret = { width: '297mm', height: '210mm' }
      else if cmd.startsWith('a5')
        ret = { width: '210mm', height: '148mm' }
      else if cmd.startsWith('a6')
        ret = { width: '148mm', height: '105mm' }
      else if cmd.startsWith('a7')
        ret = { width: '105mm', height: '74mm' }
      else if cmd.startsWith('a8')
        ret = { width: '74mm', height: '52mm' }
      else if cmd.startsWith('b0')
        ret = { width: '1456mm', height: '1030mm' }
      else if cmd.startsWith('b1')
        ret = { width: '1030mm', height: '728mm' }
      else if cmd.startsWith('b2')
        ret = { width: '728mm', height: '515mm' }
      else if cmd.startsWith('b3')
        ret = { width: '515mm', height: '364mm' }
      else if cmd.startsWith('b4')
        ret = { width: '364mm', height: '257mm' }
      else if cmd.startsWith('b5')
        ret = { width: '257mm', height: '182mm' }
      else if cmd.startsWith('b6')
        ret = { width: '182mm', height: '128mm' }
      else if cmd.startsWith('b7')
        ret = { width: '128mm', height: '91mm' }
      else if cmd.startsWith('b8')
        ret = { width: '91mm', height: '64mm' }

      if Object.keys(ret).length > 0 && cmd.endsWith('-portrait')
        tmp = ret.width
        ret.width = ret.height
        ret.height = tmp

      ret

  @findDuckTypes: (prop) =>
    for duckTypeProp, convertFunc of MdsMdSetting.duckTypes
      return convertFunc if prop is duckTypeProp
    null

  @validProps:
    global: ['width', 'height', 'size', 'theme']
    page:   ['page_number', 'template']

  @isValidProp: (page, prop) =>
    target = if page > 0 then 'page' else 'global'
    prop in MdsMdSetting.validProps[target]

  constructor: () ->
    @_settings = []

  set: (fromPage, prop, value, noFollowing = false) =>
    return false unless MdsMdSetting.isValidProp(fromPage, prop)

    if duckType = MdsMdSetting.findDuckTypes(prop)
      target = duckType(value)
    else
      target = {}
      target[prop] = value

    for targetProp, targetValue of target
      if transformer = MdsMdSetting.findTransformer(targetProp)
        transformedValue = transformer(targetValue)

        if (idx = @_findSettingIdx fromPage, targetProp, !!noFollowing)?
          @_settings[idx].value = transformedValue
        else
          @_settings.push
            page:        fromPage
            property:    targetProp
            value:       transformedValue
            noFollowing: !!noFollowing

  setGlobal: (prop, value) => @set 0, prop, value

  get: (page, prop, withGlobal = true) => @getAt(page, withGlobal)[prop]
  getGlobal: (prop) => @getAtGlobal()[prop]

  getAt: (page, withGlobal = true) =>
    props = (obj for obj in @_settings when obj.page <= page && (withGlobal || obj.page > 0))
    props.sort (a, b) -> a.page - b.page

    ret = {}
    noFollows = []

    for obj in props
      if obj.noFollowing
        noFollows[obj.page] = {} unless noFollows[obj.page]
        noFollows[obj.page][obj.property] = obj.value
      else
        ret[obj.property] = obj.value

    extend ret, noFollows[page] || {}

  getAtGlobal: => @getAt 0

  _findSettingIdx: (page, prop, noFollowing) =>
    for opts, idx in @_settings
      return idx if opts.page == page && opts.property == prop && opts.noFollowing == noFollowing
    null
