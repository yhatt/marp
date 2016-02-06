highlightJs = require 'highlight.js'
twemoji     = require 'twemoji'
extend      = require 'extend'
markdownIt  = require 'markdown-it'

module.exports = class MdsMarkdown
  @slideTagOpen:  '<div class="slide_wrapper"><div class="slide">'
  @slideTagClose: '</div></div>'

  @defOpts:
    html: true
    xhtmlOut: true
    breaks: true
    linkify: true
    highlight: @defHighlighter

  @defHighlighter: (code, lang) ->
    if lang?
      if lang == 'text' or lang == 'plain'
        return ''
      else if highlightJs.getLanguage(lang)
        try
          return highlightJs.highlight(lang, code).value
        catch _

    return highlightJs.highlightAuto(code).value

  @defPlugins:
    'markdown-it-mark': {}
    'markdown-it-emoji':
      shortcuts: {}

  @defAfter: (md) =>
    md.renderer.rules.emoji = (token, idx) -> twemoji.parse(token[idx].content)
    md.renderer.rules.hr    = (token, idx) => "#{MdsMarkdown.slideTagClose}#{MdsMarkdown.slideTagOpen}"

  @createMarkdownIt: (opts = {}, plugins = {}, after = @defAfter) =>
    md = markdownIt(extend(@defOpts, opts))

    for plugName, plugOpts of extend(@defPlugins, plugins)
      plugOpts = {} unless plugOpts?
      md.use require(plugName), plugOpts

    after md if after?
    md

  constructor: (settings) ->
    opts      = settings?.options || {}
    plugins   = settings?.plugins || {}
    afterFunc = settings?.mdAfter || @defAfter

    @markdown = @constructor.createMarkdownIt opts, plugins, afterFunc

  parse: (markdown) =>
    @lastParsed = """
                  #{MdsMarkdown.slideTagOpen}
                  #{@markdown.render markdown}
                  #{MdsMarkdown.slideTagClose}
                  """
