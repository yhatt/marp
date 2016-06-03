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

    getScreenSize = ->
      size =
        w: $(window).width()
        h: $(window).height()

      previewMargin = +getCSSvar '--preview-margin'
      size.ratio = (size.w - previewMargin * 2) / (size.h - previewMargin * 2)
      size

    applyCurrentPage = (page) ->
      $('#mds-currentPageStyle').text "@media not print { body.slide-view.screen .slide_wrapper:not(:nth-of-type(#{page})){ display:none; }}"

    applyResize = (newSlideSize) ->
      size = getScreenSize()
      css  = """
             body {
                --screen-width: #{size.w};
                --screen-height: #{size.h};
                --slide-width: #{newSlideSize?.width || 'inherit'};
                --slide-height: #{newSlideSize?.height || 'inherit'};
             }
             """

      $('#mds-sizeStyle').text css
      $('#container').toggleClass 'height-base', size.ratio > getSlideSize().ratio

    applyPageNumber = (settings, maxPage) ->
      css = ''
      page = 0

      while ++page <= maxPage
        if settings.get(page, 'page_number')
          content = ".slide_page[data-page=\"#{page}\"] { display: block; }"
          css    += "body.slide-view #{content} @media print { body #{content} } "

      $('#mds-pageNumberStyle').text css

    render = (md) ->
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

    # Initialize
    $(document).on 'click', 'a', (e) ->
      e.preventDefault()
      ipc.sendToHost 'linkTo', $(e.currentTarget).attr('href')

    $(window).resize (e) -> applyResize()
    applyResize()
