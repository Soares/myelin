myelin = require '../lib/myelin'
vows = require 'vows'
assert = require 'assert'
jsdom = require 'jsdom'
fs = require 'fs'
jQuery = fs.readFileSync("./vendor/jquery-1.6.2.js").toString()
Backbone = require 'backbone'
_ = require('underscore')._

initialize = ->
    console.log 'DOM initialized. GOGOGO!'

jsdom.env
    html: fs.readFileSync("./test.html")
    src: [jQuery]
    done: initialize

class MyRadio extends myelin.Radio
    clean: (value) =>
        switch value
            when "one" then 1
            when "two" then 2
            when "three" then 3
    render: (value) =>
        switch value
            when 1 then "one"
            when 2 then "two"
            when 3 then "three"

class YesNo extends myelin.Handler
    render: (value) => if value then "yes" else "no"

class View extends myelin.View
    el: '#example'
    sync: {
        text: [true, '.text']
        radio: [MyRadio, '.radio']
        checkbox: [true, {handler: YesNo, selector: '.checkbox'}]
        button: [true, '.button']
        submit: [true, '.submit']
        fake: [true, '.nonexistant']
        immediate: ['keyup', '.immediate']
        ex2: 'keyup this'
    }

model = new Backbone.Model
    text: "Welcome!"
    radio: 1
    ex2: "initial"

console.log 'stuff here says', $('#example')

view = new View model: new Backbone.Model
    text: "Welcome!"
    radio: 1

vows.describe('myelin')
    .export module
