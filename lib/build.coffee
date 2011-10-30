coffee = require 'coffee-script'
ck = require 'coffeekup'
fs = require 'fs'
sys = require 'sys'
proc = require 'child_process'

data =
	load: (path) -> ck.render (fs.readFileSync path, 'utf-8'), data
	pygmented: (path, callback) -> proc.exec "pygmentize -f html #{path}", callback
	markdown: (path, callback) -> proc.exec "markdown < #{path}", callback
	stylus: (path, callback) -> proc.exec "stylus -u nib < #{path}", callback
	paste: (path, callback) -> fs.readFile path, 'utf-8', callback


console.log data.load 'index.coffee'
