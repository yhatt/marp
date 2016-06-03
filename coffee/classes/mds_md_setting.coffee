module.exports = class MdsMdSetting
  @transformers:
    page_number: (v) -> v is 'true'

  @defaultTransformer: null

  @findTransformer: (prop) =>
    for transformerProp, transformer of MdsMdSetting.transformers
      return transformer if prop is transformerProp

    MdsMdSetting.defaultTransformer

  @validProps:
    global: []
    page:   ['page_number']

  @isValidProp: (page, prop) =>
    target = if page > 0 then 'page' else 'global'
    prop in MdsMdSetting.validProps[target]

  constructor: () ->
    @_settings = []

  set: (fromPage, prop, value) =>
    return false unless MdsMdSetting.isValidProp(fromPage, prop)
    return false unless transformer = MdsMdSetting.findTransformer(prop)

    transformedValue = transformer(value)

    if (idx = @_findSettingIdx fromPage, prop)?
      @_settings[idx].value = transformedValue
    else
      @_settings.push
        page:     fromPage
        property: prop
        value:    transformedValue

    transformedValue

  setGlobal: (prop, value) => @set 0, prop, value

  get: (page, prop, withGlobal = true) => @getAt(page, withGlobal)[prop]
  getGlobal: (prop) => @getAtGlobal()[prop]

  getAt: (page, withGlobal = true) =>
    props = (obj for obj in @_settings when obj.page <= page && (withGlobal || obj.page > 0))
    props.sort (a, b) -> a.page - b.page

    ret = {}
    ret[obj.property] = obj.value for obj in props
    ret

  getAtGlobal: => @getAt 0

  _findSettingIdx: (page, prop) =>
    for opts, idx in @_settings
      return idx if opts.page == page && opts.property == prop
    null
