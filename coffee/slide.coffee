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
$(window).on 'load', ->

  # Resizing
  $(window).resize ->
    psCss = $('#mds-previewStyle')
    psCss = $('<style id="mds-previewStyle"></style>').appendTo('head') if psCss.length < 1
    psCss.text """
               :root { --screen-width: #{$(window).width()}; --screen-height: #{$(window).height()};
                       --screen-width-px: #{$(window).width()}px; --screen-height-px: #{$(window).height()}px; }
               """
  .trigger('resize')

  ipc.sendToHost 'initializedSlide'
