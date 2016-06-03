highlightJs  = require 'highlight.js'
twemoji      = require 'twemoji'
extend       = require 'extend'
markdownIt   = require 'markdown-it'
Path         = require 'path'
fs           = require 'fs'
MdsMdSetting = require './mds_md_setting'

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

  @createMarkdownIt: (opts, plugins) ->
    md = markdownIt(opts)
    md.use(require(plugName), plugOpts ? {}) for plugName, plugOpts of plugins
    md

  rulers: []
  imageDirs: []
  settings: new MdsMdSetting

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
    @_settings  = new MdsMdSetting
    @lastParsed = """
                  #{MdsMarkdown.slideTagOpen(1)}
                  #{@markdown.render markdown}
                  #{MdsMarkdown.slideTagClose(@_rulers.length + 1)}
                  """
    ret =
      parsed: @lastParsed
      rulerChanged: @rulers.join(",") != @_rulers.join(",")

    @rulers   = ret.rulers   = @_rulers
    @settings = ret.settings = @_settings
    ret

  renderers:
    image: (tokens, idx, options, env, self) ->
      src = decodeURIComponent(tokens[idx].attrs[tokens[idx].attrIndex('src')][1])

      existFile = (fname) ->
        try
          unless fs.accessSync(fname, fs.R_OK)?
            return true if fs.lstatSync(fname).isFile()
        false

      return tokens[idx].attrs[tokens[idx].attrIndex('src')][1] = src if existFile(src)

      if @imageDirs?.length > 0
        for dir in @imageDirs
          imgPath = Path.resolve(dir, src)
          return tokens[idx].attrs[tokens[idx].attrIndex('src')][1] = imgPath if existFile(imgPath)

    html_block: (tokens, idx, options, env, self) ->
      {content} = tokens[idx]

      return if content.substring(0, 3) isnt '<!-'

      if matched = /^<!-{2,}\s*([\s\S]*?)\s*-{2,}>$/m.exec(content)

        for mathcedLine in matched[1].split(/[\r\n]+/)
          parsed = /^\s*([\$\*]?)(\w+)\s*:\s*(.*)\s*$/.exec(mathcedLine)

          if parsed
            if parsed[1] is '$'
              @_settings.setGlobal parsed[2], parsed[3]
            else
              @_settings.set (@_rulers.length || 0) + 1, parsed[2], parsed[3], parsed[1] is '*'
