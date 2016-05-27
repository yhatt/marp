clsMdsMarkdown = require './classes/mds_markdown'
Markdown       = new clsMdsMarkdown
ipc            = require('electron').ipcRenderer

window.jQuery = window.$ = require('jquery')

applyCurrentPage = (page) ->
  $('#mds-currentPageStyle').text "@media not print { body.slide-view.screen .slide_wrapper:not(:nth-of-type(#{page})){ display:none; }}"

applyScreenWidth = ->
  size = { w: $(window).width(), h: $(window).height() }
  css  = ":root { --screen-width:#{size.w}; --screen-height:#{size.h}; --screen-width-px:#{size.w}px; --screen-height-px:#{size.h}px; }"

  $('#mds-screenWidthStyle').text css

ipc.on 'render', (e, md) ->
  markdown = Markdown.parse(md)
  document.getElementById('markdown').innerHTML = markdown.parsed

  ipc.sendToHost 'rulerChanged', markdown.rulers if markdown.rulerChanged

ipc.on 'currentPage', (e, page) -> applyCurrentPage page
ipc.on 'setClass', (e, classes) -> $('body').attr 'class', classes

# Initialize
$ ->
  $(document).on 'click', 'a', (e) ->
    e.preventDefault()
    ipc.sendToHost 'linkTo', $(e.target).attr('href')

$(window).on 'load', ->
  $(window).resize applyScreenWidth
  applyScreenWidth()

  ipc.sendToHost 'initializedSlide'
