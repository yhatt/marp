highlightJs = require 'highlight.js'
twemoji     = require 'twemoji'
extend      = require 'extend'
markdownIt  = require 'markdown-it'
Path        = require 'path'
fs          = require 'fs'

module.exports = class MdsMarkdown
  @slideTagOpen:  (page) -> '<div class="slide_wrapper" id="' + page + '"><div class="slide"><div class="slide_inner">'
  @slideTagClose: (page) -> '</div><span class="slide_page" data-page="' + page + '">' + page + '</span></div></div>'

  @highlighter: (code, lang) ->
    if lang?
      if lang == 'text' or lang == 'plain'
        return ''
      else if highlightJs.getLanguage(lang)
        try
          return highlightJs.highlight(lang, code).value

    highlightJs.highlightAuto(code).value

  @default:
    options:
      html: true
      xhtmlOut: true
      breaks: true
      linkify: true
      highlight: @highlighter

    plugins:
      'markdown-it-mark': {}
      'markdown-it-emoji':
        shortcuts: {}

  @validSettings:
    page_number:               (v) -> v is 'true'
    page_number_exclude_title: (v) -> v is 'true'

  @createMarkdownIt: (opts, plugins) ->
    md = markdownIt(opts)
    md.use(require(plugName), plugOpts ? {}) for plugName, plugOpts of plugins
    md

  rulers: []
  imageDirs: []
  settings: {}

  constructor: (settings) ->
    opts      = extend(MdsMarkdown.default.options, settings?.options || {})
    plugins   = extend(MdsMarkdown.default.plugins, settings?.plugins || {})
    @markdown = MdsMarkdown.createMarkdownIt.call(@, opts, plugins)
    @afterCreate()

  afterCreate: =>
    md      = @markdown
    {rules} = md.renderer

    defaultRenderers =
      image:      rules.image
      html_block: rules.html_block

    extend rules, {
      emoji: (token, idx) ->
        twemoji.parse(token[idx].content)

      hr: (token, idx) =>
        ruler.push token[idx].map[0] if ruler = @_rulers
        "#{MdsMarkdown.slideTagClose(ruler.length || '')}#{MdsMarkdown.slideTagOpen(if ruler then ruler.length + 1 else '')}"

      image: (args...) =>
        @renderers.image.apply(@, args)
        defaultRenderers.image.apply(@, args)

      html_block: (args...) =>
        @renderers.html_block.apply(@, args)
        defaultRenderers.html_block.apply(@, args)
    }

  parse: (markdown) =>
    @_rulers    = []
    @_settings  = {}
    @lastParsed = """
                  #{MdsMarkdown.slideTagOpen(1)}
                  #{@markdown.render markdown}
                  #{MdsMarkdown.slideTagClose(@_rulers.length + 1)}
                  """
    @_settings  = @verifySetting(@_settings)
    ret =
      parsed: @lastParsed
      rulerChanged: @rulers.join(",") != @_rulers.join(",")
      settingChanged: JSON.stringify(@settings) != JSON.stringify(@_settings)

    @rulers   = ret.rulers   = @_rulers
    @settings = ret.settings = @_settings
    ret

  verifySetting: (dry) =>
    verified = {}

    for prop, val of dry
      verifyFunc = MdsMarkdown.validSettings[prop]
      verified[prop] = verifyFunc(val) if verifyFunc

    verified

  renderers:
    image: (tokens, idx, options, env, self) ->
      if @imageDirs?.length > 0
        src = tokens[idx].attrs[tokens[idx].attrIndex('src')][1]

        for dir in @imageDirs
          resolvedPath = Path.resolve(dir, src)

          try
            unless fs.accessSync(resolvedPath, fs.R_OK)?
              if fs.lstatSync(resolvedPath).isFile()
                tokens[idx].attrs[tokens[idx].attrIndex('src')][1] = resolvedPath
                return

    html_block: (tokens, idx, options, env, self) ->
      {content} = tokens[idx]

      return if content.substring(0, 3) isnt '<!-'

      if matched = /^<!-{2,}\s*([\s\S]*?)\s*-{2,}>$/m.exec(content)
        for mathcedLine in matched[1].split(/[\r\n]+/)
          parsed = /^\s*(\w+)\s*:\s*(.*)\s*$/.exec(mathcedLine)
          @_settings[parsed[1]] = parsed[2] if parsed
