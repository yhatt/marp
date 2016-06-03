MdsMarkdown = require './classes/mds_markdown'
Markdown    = new MdsMarkdown
ipc         = require('electron').ipcRenderer

document.addEventListener 'DOMContentLoaded', ->
  $ = window.jQuery = window.$ = require('jquery')

  do ($) ->
    getCSSvar = (prop) -> document.defaultView.getComputedStyle(document.body).getPropertyValue(prop)

    getSlideSize = ->
      size =
        w: +getCSSvar '--slide-width'
        h: +getCSSvar '--slide-height'

      size.ratio = size.w / size.h
      size

    applySlideSize = (width, height) ->
      css = """
            body {
              --slide-width: #{width || 'inherit'};
              --slide-height: #{height || 'inherit'};
            }
            """

      $('#mds-slideSizeStyle').text css
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
      $('#mds-screenSizeStyle').text "body { --screen-width: #{size.w}; --screen-height: #{size.h}; }"
      $('#container').toggleClass 'height-base', size.ratio > getSlideSize().ratio

    applyCurrentPage = (page) ->
      $('#mds-currentPageStyle').text "@media not print { body.slide-view.screen .slide_wrapper:not(:nth-of-type(#{page})){ display:none; }}"

    applyPageNumber = (settings, maxPage) ->
      css = ''
      page = 0

      while ++page <= maxPage
        if settings.get(page, 'page_number')
          content = ".slide_page[data-page=\"#{page}\"] { display: block; }"
          css    += "body.slide-view #{content} @media print { body #{content} } "

      $('#mds-pageNumberStyle').text css

    sendPdfOptions = (opts) ->
      slideSize = getSlideSize()

      opts.exportSize =
        width:  Math.floor(slideSize.w * 25400 / 96)
        height: Math.floor(slideSize.h * 25400 / 96)

      ipc.sendToHost 'responsePdfOptions', opts

    render = (md) ->
      applySlideSize md.settings.getGlobal('width'), md.settings.getGlobal('height')
      applyPageNumber(md.settings, md.rulers.length + 1)

      $('#markdown').html(md.parsed)
      renderNotify(md)

    renderNotify = (md) ->
      ipc.sendToHost 'rendered'
      ipc.sendToHost 'rulerChanged', md.rulers if md.rulerChanged

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
