highlightJs  = require 'highlight.js'
twemoji      = require 'twemoji'
extend       = require 'extend'
markdownIt   = require 'markdown-it'
Path         = require 'path'
MdsMdSetting = require './mds_md_setting'
{exist}      = require './mds_file'

module.exports = class MdsMarkdown
  @slideTagOpen:  (page) -> '<div class="slide_wrapper" id="' + page + '"><div class="slide"><div class="slide_bg"></div><div class="slide_inner">'
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

  @generateAfterRender: ($) ->
    (md) ->
      mdElm = $("<div>#{md.parsed}</div>")

      mdElm.find('p > img[alt~="bg"]').each ->
        $t  = $(@)
        p   = $t.parent()
        bg  = $t.parents('.slide_wrapper').find('.slide_bg')
        src = $t[0].src
        alt = $t.attr('alt')
        elm = $('<div class="slide_bg_img"></div>').css('backgroundImage', "url(#{src})").attr('data-alt', alt)

        for opt in alt.split(/\s+/)
          elm.css('backgroundSize', "#{m[1]}%") if m = opt.match(/^(\d+(?:\.\d+)?)%$/)

        elm.appendTo(bg)
        $t.remove()
        p.remove() if p.children(':not(br)').length == 0 && /^\s*$/.test(p.text())

      mdElm.find('img[alt*="%"]').each ->
        for opt in $(@).attr('alt').split(/\s+/)
          if m = opt.match(/^(\d+(?:\.\d+)?)%$/)
            $(@).css('zoom', parseFloat(m[1]) / 100.0)

      mdElm
        .children('.slide_wrapper')
        .each ->
          # Page directives for themes
          page = $(@)[0].id
          $(@).attr("data-#{prop}", val) for prop, val of md.settings.getAt(+page, false)

          # Detect only elements
          inner = $(@).find('.slide > .slide_inner')

          heads = $(inner).children(':header').length
          $(@).addClass('only-headings') if heads > 0 && $(inner).children().length == heads

          quotes = $(inner).children('blockquote').length
          $(@).addClass('only-blockquotes') if quotes > 0 && $(inner).children().length == quotes

      md.parsed = mdElm.html()

  rulers: []
  imageDirs: []
  settings: new MdsMdSetting
  afterRender: null

  constructor: (settings) ->
    opts         = extend({}, MdsMarkdown.default.options, settings?.options || {})
    plugins      = extend({}, MdsMarkdown.default.plugins, settings?.plugins || {})
    @afterRender = settings?.afterRender || null
    @markdown    = MdsMarkdown.createMarkdownIt.call(@, opts, plugins)
    @afterCreate()

  afterCreate: =>
    md      = @markdown
    {rules} = md.renderer

    defaultRenderers =
      image:      rules.image
      html_block: rules.html_block

    extend rules,
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

  parse: (markdown) =>
    @_rulers          = []
    @_settings        = new MdsMdSetting
    @settingsPosition = []
    @lastParsed       = """
                        #{MdsMarkdown.slideTagOpen(1)}
                        #{@markdown.render markdown}
                        #{MdsMarkdown.slideTagClose(@_rulers.length + 1)}
                        """
    ret =
      parsed: @lastParsed
      settingsPosition: @settingsPosition
      rulerChanged: @rulers.join(",") != @_rulers.join(",")

    @rulers   = ret.rulers   = @_rulers
    @settings = ret.settings = @_settings

    @afterRender(ret) if @afterRender?
    ret

  renderers:
    image: (tokens, idx, options, env, self) ->
      src = decodeURIComponent(tokens[idx].attrs[tokens[idx].attrIndex('src')][1])

      return tokens[idx].attrs[tokens[idx].attrIndex('src')][1] = src if exist(src)

      if @imageDirs?.length > 0
        for dir in @imageDirs
          imgPath = Path.resolve(dir, src)
          return tokens[idx].attrs[tokens[idx].attrIndex('src')][1] = imgPath if exist(imgPath)

    html_block: (tokens, idx, options, env, self) ->
      {content} = tokens[idx]
      return if content.substring(0, 3) isnt '<!-'

      if matched = /^(<!-{2,}\s*)([\s\S]*?)\s*-{2,}>$/m.exec(content)
        spaceLines = matched[1].split("\n")
        lineIndex  = tokens[idx].map[0] + spaceLines.length - 1
        startFrom  = spaceLines[spaceLines.length - 1].length

        for mathcedLine in matched[2].split("\n")
          parsed = /^(\s*)(([\$\*]?)(\w+)\s*:\s*(.*))\s*$/.exec(mathcedLine)

          if parsed
            startFrom += parsed[1].length
            pageIdx = @_rulers.length || 0

            if parsed[3] is '$'
              @_settings.setGlobal parsed[4], parsed[5]
            else
              @_settings.set pageIdx + 1, parsed[4], parsed[5], parsed[3] is '*'

            @settingsPosition.push
              pageIdx: pageIdx
              lineIdx: lineIndex
              from: startFrom
              length: parsed[2].length
              property: "#{parsed[3]}#{parsed[4]}"
              value: parsed[5]

          lineIndex++
          startFrom = 0
