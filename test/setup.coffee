class Radio extends myelin.Radio
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
        radio: [Radio, '.radio']
        checkbox: [true, {handler: YesNo, selector: '.checkbox'}]
        button: [true, '.button']
        submit: [true, '.submit']
        fake: [true, '.nonexistant']
        immediate: ['keyup', '.immediate']
    }

class View2 extends myelin.View
    el: '#example2'
    sync: {ex2: 'keyup this'}

@model = new Backbone.Model
    text: "Welcome!"
    radio: 1

@view = new View {model}

@model2 = new Backbone.Model
    ex2: "initial"

@view2 = new View2 {model: model2}
