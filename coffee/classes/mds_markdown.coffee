highlightJs = require 'highlight.js'
twemoji     = require 'twemoji'
extend      = require 'extend'
markdownIt  = require 'markdown-it'

module.exports = class MdsMarkdown
  @slideTagOpen:  (page) -> '<div class="slide_wrapper" id="' + page + '"><div class="slide"><div class="slide_inner">'
  @slideTagClose: (page) -> '</div><span class="slide_page" data-page="' + page + '">' + page + '</span></div></div>'

  rulers: []

  @defHighlighter: (code, lang) ->
    if lang?
      if lang == 'text' or lang == 'plain'
        return ''
      else if highlightJs.getLanguage(lang)
        try
          return highlightJs.highlight(lang, code).value
        catch _

    return highlightJs.highlightAuto(code).value

  @defOpts:
    html: true
    xhtmlOut: true
    breaks: true
    linkify: true
    highlight: @defHighlighter

  @defPlugins:
    'markdown-it-mark': {}
    'markdown-it-emoji':
      shortcuts: {}

  @defAfter: (md, instance) =>
    md.renderer.rules.emoji = (token, idx) -> twemoji.parse(token[idx].content)
    md.renderer.rules.hr    = (token, idx) =>
      ruler.push token[idx].map[0] if ruler = instance?._rulers
      "#{MdsMarkdown.slideTagClose(ruler.length || '')}#{MdsMarkdown.slideTagOpen(if ruler then ruler.length + 1 else '')}"

  @createMarkdownIt: (opts = {}, plugins = {}, after = @defAfter, instance = null) =>
    md = markdownIt(extend(@defOpts, opts))

    for plugName, plugOpts of extend(@defPlugins, plugins)
      plugOpts = {} unless plugOpts?
      md.use require(plugName), plugOpts

    after md, instance if after?
    md

  constructor: (settings) ->
    opts      = settings?.options || {}
    plugins   = settings?.plugins || {}
    afterFunc = settings?.mdAfter || @defAfter

    @markdown = @constructor.createMarkdownIt opts, plugins, afterFunc, @

  parse: (markdown) =>
    @_rulers    = []
    @lastParsed = """
                  #{MdsMarkdown.slideTagOpen(1)}
                  #{@markdown.render markdown}
                  #{MdsMarkdown.slideTagClose(@_rulers.length + 1)}
                  """
    ret =
      parsed: @lastParsed
      rulerChanged: @rulers.join(",") != @_rulers.join(",")

    @rulers = ret.rulers = @_rulers
    ret
