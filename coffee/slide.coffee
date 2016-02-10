clsMdsMarkdown = require './classes/mds_markdown'
Markdown       = new clsMdsMarkdown
ipc            = require('electron').ipcRenderer

window.jQuery = window.$ = require('jquery')

# Markdown rendering
ipc.on 'render', (e, md) ->
  markdown = Markdown.parse(md)
  document.getElementById('markdown').innerHTML = markdown.parsed

  ipc.sendToHost 'rulerChanged', markdown.rulers if markdown.rulerChanged

# Current page
ipc.on 'currentPage', (e, page) ->
  currentPageStyle =
    """
    @media not print {
      body.slide-view.screen .slide_wrapper:not(:nth-of-type(#{page})) { display: none; }
    }
    """

  cpCss = $('#mds-currentPageStyle')
  cpCss = $('<style id="mds-currentPageStyle"></style>').appendTo('head') if cpCss.length < 1
  cpCss.text currentPageStyle

# Mode
ipc.on 'setClass', (e, classes) -> $('body').attr 'class', classes

# Initialize
$ ->
  # Slize size from css
  slideSize = do ->
    sizeElm = $('<div id="slide-size">').hide()
    $('body').append sizeElm

    ret =
      width: sizeElm.outerWidth()
      height: sizeElm.outerHeight()
      viewWidth: sizeElm.width()
      viewHeight: sizeElm.height()

    ret.ratio = ret.width / ret.height

    sizeElm.remove()
    ret

  # Resizing
  $(window).resize ->

    # Client area size (excluding margin)
    cSize =
      width:  $(window).width() - (slideSize.width - slideSize.viewWidth)
      height: $(window).height() - (slideSize.height - slideSize.viewHeight)

    calcedWidth = cSize.height * slideSize.ratio

    # Size for screen preview
    sSize =
      width:  if calcedWidth >= cSize.width then cSize.width else calcedWidth
      height: if calcedWidth >= cSize.width then cSize.width / slideSize.ratio else cSize.height

    # Size for list preview
    lSize =
      width:  cSize.width
      height: cSize.width / slideSize.ratio

    styleGen = (klass, size_obj) ->
      """
      body.slide-view.#{klass} .slide_wrapper {
        width: #{size_obj.width}px;
        height: #{size_obj.height}px;
      }
      body.slide-view.#{klass} .slide_wrapper > .slide {
        transform: scale(#{size_obj.width / slideSize.width}) translateY(-50%) translateY(#{slideSize.height / 2}px);
      }
      """

    previewStyle =
      """
      @media not print {
        #{styleGen 'screen', sSize}
        #{styleGen 'list', lSize}
      }
      """

    psCss = $('#mds-previewStyle')
    psCss = $('<style id="mds-previewStyle"></style>').appendTo('head') if psCss.length < 1
    psCss.text previewStyle

  .trigger('resize')
