MdsMarkdown = require './classes/mds_markdown'
Markdown    = new MdsMarkdown
ipc         = require('electron').ipcRenderer

# Electron >= 1.2.0 caused failing quietly
# [Note] https://github.com/electron/electron/issues/5719
window.jQuery = window.$ = require('jquery')

applyCurrentPage = (page) ->
  $('#mds-currentPageStyle').text "@media not print { body.slide-view.screen .slide_wrapper:not(:nth-of-type(#{page})){ display:none; }}"

applyScreenWidth = ->
  size = { w: $(window).width(), h: $(window).height() }
  css  = ":root { --screen-width:#{size.w}; --screen-height:#{size.h}; --screen-width-px:#{size.w}px; --screen-height-px:#{size.h}px; }"

  $('#mds-screenWidthStyle').text css

render = (md) ->
  s = md.settings

  $('#markdown')
    .toggleClass('page-number', (s.page_number || s.page_number_exclude_title) || false)
    .toggleClass('page-number-exclude-first-page', s.page_number_exclude_title || false)
    .html(md.parsed)

  renderNotify(md)

renderNotify = (md) ->
  ipc.sendToHost 'rulerChanged',     md.rulers   if md.rulerChanged
  ipc.sendToHost 'mdSettingChanged', md.settings if md.settingChanged

ipc.on 'render', (e, md) -> render(Markdown.parse(md))
ipc.on 'currentPage', (e, page) -> applyCurrentPage page
ipc.on 'setClass', (e, classes) -> $('body').attr 'class', classes
ipc.on 'setImageDirectories', (e, dirs) -> Markdown.imageDirs = dirs

# Initialize
$ ->
  $(document).on 'click', 'a', (e) ->
    e.preventDefault()
    ipc.sendToHost 'linkTo', $(e.currentTarget).attr('href')

  $(window).resize applyScreenWidth
  applyScreenWidth()

  ipc.sendToHost 'initializedSlide'
