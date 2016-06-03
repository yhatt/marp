extend = require 'extend'

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

  @defaultTransformer: null

  @findTransformer: (prop) =>
    for transformerProp, transformer of MdsMdSetting.transformers
      return transformer if prop is transformerProp

    MdsMdSetting.defaultTransformer

  @validProps:
    global: ['width', 'height']
    page:   ['page_number']

  @isValidProp: (page, prop) =>
    target = if page > 0 then 'page' else 'global'
    prop in MdsMdSetting.validProps[target]

  constructor: () ->
    @_settings = []

  set: (fromPage, prop, value, noFollowing = false) =>
    return false unless MdsMdSetting.isValidProp(fromPage, prop)
    return false unless transformer = MdsMdSetting.findTransformer(prop)

    transformedValue = transformer(value)

    if (idx = @_findSettingIdx fromPage, prop, !!noFollowing)?
      @_settings[idx].value = transformedValue
    else
      @_settings.push
        page:        fromPage
        property:    prop
        value:       transformedValue
        noFollowing: !!noFollowing

    transformedValue

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
