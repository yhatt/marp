Markdown    = new (require './classes/mds_markdown')
ipc         = require('electron').ipcRenderer

document.addEventListener 'DOMContentLoaded', ->
  $ = window.jQuery = window.$ = require('jquery')

  do ($) ->
    themes = {}
    themes.current = -> $('#theme-css').attr('href')
    themes.default = themes.current()
    themes.apply = (path = null) ->
      toApply = path || themes.default

      if toApply isnt themes.current()
        $('#theme-css').attr('href', toApply)
        setTimeout applyScreenSize, 20

    setStyle = (identifier, css) ->
      id  = "mds-#{identifier}Style"
      elm = $("##{id}")
      elm = $("<style id=\"#{id}\"></style>").appendTo(document.head) if elm.length <= 0
      elm.text(css)

    getCSSvar = (prop) -> document.defaultView.getComputedStyle(document.body).getPropertyValue(prop)

    getSlideSize = ->
      size =
        w: +getCSSvar '--slide-width'
        h: +getCSSvar '--slide-height'

      size.ratio = size.w / size.h
      size

    applySlideSize = (width, height) ->
      setStyle 'slideSize',
        """
        body {
          --slide-width: #{width || 'inherit'};
          --slide-height: #{height || 'inherit'};
        }
        """
      applyScreenSize()

    getScreenSize = ->
      size =
        w: $(window).width()
        h: $(window).height()

      previewMargin = +getCSSvar '--preview-margin'
      size.ratio = (size.w - previewMargin * 2) / (size.h - previewMargin * 2)
      size

    applyScreenSize = ->
      size = getScreenSize()
      setStyle 'screenSize', "body { --screen-width: #{size.w}; --screen-height: #{size.h}; }"
      $('#container').toggleClass 'height-base', size.ratio > getSlideSize().ratio

    applyCurrentPage = (page) ->
      setStyle 'currentPage', "@media not print { body.slide-view.screen .slide_wrapper:not(:nth-of-type(#{page})){ display:none; }}"

    render = (md) ->
      themes.apply md.settings.getGlobal('theme')
      applySlideSize md.settings.getGlobal('width'), md.settings.getGlobal('height')

      mdElm = $('#markdown').html(md.parsed)
      mdElm
        .children('.slide_wrapper')
        .each ->
          # Page directives for themes
          page = $(@)[0].id
          $(@).attr("data-#{prop}", val) for prop, val of md.settings.getAt(+page, false)

          # Detect only headings
          inner = $(@).find('.slide > .slide_inner')
          heads = $(inner).children(':header').length

          $(@).addClass('only-headings') if heads > 0 && $(inner).children().length == heads

      renderNotify(md)

    renderNotify = (md) ->
      ipc.sendToHost 'rendered'
      ipc.sendToHost 'rulerChanged', md.rulers if md.rulerChanged

    sendPdfOptions = (opts) ->
      slideSize = getSlideSize()

      opts.exportSize =
        width:  Math.floor(slideSize.w * 25400 / 96)
        height: Math.floor(slideSize.h * 25400 / 96)

      ipc.sendToHost 'responsePdfOptions', opts

    ipc.on 'render', (e, md) -> render(Markdown.parse(md))
    ipc.on 'currentPage', (e, page) -> applyCurrentPage page
    ipc.on 'setClass', (e, classes) -> $('body').attr 'class', classes
    ipc.on 'setImageDirectories', (e, dirs) -> Markdown.imageDirs = dirs
    ipc.on 'requestPdfOptions', (e, opts) -> sendPdfOptions(opts || {})

    # Initialize
    $(document).on 'click', 'a', (e) ->
      e.preventDefault()
      ipc.sendToHost 'linkTo', $(e.currentTarget).attr('href')

    $(window).resize (e) -> applyScreenSize()
    applyScreenSize()
