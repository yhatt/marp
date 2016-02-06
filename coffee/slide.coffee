ipc = require('electron').ipcRenderer

ipc.on 'render', (e, html) ->
  document.getElementById('markdown').innerHTML = html
