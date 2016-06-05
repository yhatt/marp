fs = require 'fs'

module.exports =
  exist: (fname) ->
    try
      unless fs.accessSync(fname, fs.R_OK)?
        return true if fs.lstatSync(fname).isFile()
    false
