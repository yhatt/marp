'use strict';

var app = require('app');
var BrowserWindow = require('browser-window');

require('crash-reporter').start();

var main_window = null;

app.on('window-all-closed', function(){
  if (process.platform != 'darwin') app.quit();
});

app.on('ready', function(){
  main_window = new BrowserWindow({ width: 800, height: 300 });
  main_window.loadUrl('file://' + __dirname + '/index.html');

  main_window.on('closed', function() { main_window = null; });
});
