# Save a reference to the global object
root = this

# Save a reference to the current myelin object
previousMyelin = root.myelin

if typeof exports isnt 'undefined' then myelin = exports
else myelin = root.myelin = {}

# require underscore, if we're on the server, and it's not already present.
_ = root._
if not _ and require? then _ = require('underscore')._

# require backbone, if we're on the server, and it's not alraedy present.
Backbone = root.Backbone
if not Backbone and require? then Backbone = require('backbone')

# for myelin's purposes, jQuery or Zepto owns the $ variable
$ = root.jQuery or root.Zepto

# runs myelin in __noConflict__ mode, returning the `myelin` variable
# to its previous owner. Returns a reference to this `myelin` object.
myelin.noConflict = ->
    root.myelin = previousMyelin
    return this

# A list of events that, placed at the beginning of selectors, will be
# recognized as events and not part of the selector.
# myelin whitelists events instead of blacklisting tags to that you can use
# selectors that include non-standard tags from other non-html formats and
# documents such as SVG or custom XML.
myelin.events = [
    'blur', 'focus', 'focusin', 'focusout', 'load', 'resize', 'scroll'
    'unload', 'click', 'dblclick', 'mousedown', 'mouseup', 'mousemove'
    'mouseover', 'mouseout', 'mouseenter', 'mouseleave', 'change', 'select'
    'submit', 'keydown', 'keypress', 'keyup', 'error'
]

# A class that handles all interaction between the DOM and the Model.
# It performs the following four basic actions:
#   get: given an element, returns the value to be synced for that element
#   clean: given an element value, clean it for setting on the model
#   render: given a model valeu, render it for display on the element
#   set: given an element and a value, set the value on the element
# It also has three attributes that control behavior:
#   domEvent: the event to listen for on the element (click, change, etc.)
#       can also be a function that takes the element and returns the event
#       if falsy, the model will not listen to DOM events
#   modelEvent: the event to listen for on the model (change:attribute, etc.)
#       can also be a function that takes the attribute and returns the event
#       if falsy, the element will not change for model events
#   preventDefault: if true, prevents the default DOM event from occuring
# For convenience, the constructor can take an 'event' kwarg in an options dict,
# which, if present, overrides domEvent.
class Handler
    constructor: (options) -> if options?.event then @domEvent = options.event

    # Get the value from the DOM element
    get: (el) -> el.html()

    # Clean the value for sending to the model
    clean: (value) -> value

    # Prepare the model's value for display
    render: (value) -> value

    # Set the value on the DOM element
    set: (el, value) -> el.html value

    # The event to listen for on the DOM element, or falsy if the model does not
    # listen to the DOM
    domEvent: false

    # The event to listen for on the model, or falsy if the DOM does not listen
    # to the model
    modelEvent: (attribute) -> "change:#{attribute}"

    # Whether or not the default DOM event should be stifled
    preventDefault: false

# A handler specifically meant for html anchors
class Link extends Handler
    domEvent: 'click'

# A handler that gets and sets using jQuery .val()
class Input extends Handler
    domEvent: 'change'
    get: (el) -> el.val()
    set: (el, value) -> el.val value

# An Input handler that responds to click events and ignores the model
class Button extends Input
    domEvent: 'click'
    get: (el) ->
        if el.is('button') then el.html() else el.val()
    set: (el, value) ->
        if el.is('button') then el.html(value) else el.val(value)

# An Input handler that responds to submit events, ignores the model, and
# prevents the default event
class Submit extends Input
    domEvent: 'submit'
    preventDefault: true

# An Input button for checkboxes. It `get`s a boolean value and `set`s the
# checkbox's checked attribute.
class Checkbox extends Input
    get: (el) -> el.is ':checked'
    set: (el, value) ->
        if value then el.attr('checked', 'checked') else el.removeAttr 'checked'
    render: (value) -> if value then true else false

# An Input handler for radio fields. For this axon, `el` will be a collection of
# elements in the radio set. `get` will return the value of the checked field,
# and `set` will cause only the field with the matching value to be checked.
class Radio extends Input
    get: (el) -> el.filter(':checked').val()
    set: (el, value) ->
        el.removeAttr 'checked'
        el.filter("[value=#{value}]").attr 'checked', 'checked'

# An Input handler for password fields. The user-entered password will never get
# sent to the model, a bcrypt-encrypted hash will be sent instead. This helps
# developers remember to never send unencrypted passwords across the line, and
# is absolutely essential with tools like spine that auto-sync model data with
# the server.
# This handler isn't used by default, as it will alter the length of the
# password that displays on the input field. This can be unexpected, especially
# when there is a 'password confirmation' field.
class Password extends Input
    clean: (value) ->
        bcrypt = require 'bcrypt'
        salt = bcrypt.gen_salt_sync
        bcrypt.encrypt_sync value, salt


# Used intertally to see if something is a handler class.
# Guesses by duck-typing the prototype.
isHandlerClass = (fn) ->
    return (_.isFunction fn) and
           (fn::) and (fn::constructor) and
           (fn::get) and (fn::set) and
           (fn::clean) and (fn::render)


class Axon
    constructor: (options={}) ->
        # if attribute is not given, the attribute function will be used to
        # dynamically determine the attribute from the elements
        if options.attribute then @attribute = options.attribute

        # If selector is not given, then the attribute _must_ be given, and will
        # be used immediately with the Axon.selector function to determine the
        # selector. `selector` will never be a function on an instantiated Axon.
        if options.selector is 'this' then @selector = false
        else if options.selector? then @selector = options.selector
        else @selector = @selector @attribute

        # If a handler and event are given, override the handler's event
        if options.handler instanceof Handler
            @handler = options.handler
            if options.event then @handler.event = options.event
        else if options.handler and options.event
            @handler = new options.handler event: options.event
        else if options.handler
            @handler = new options.handler
        # If only an event is given, save it for later instantiation
        else if options.event then @event = options.event

        # These are the links that an axon needs before it can be used.
        @scope = @model = null

    # selector works like a classmethod: it will create a selector from an
    # attribute at instantiation, but `selector` will always be a string
    # (not a function) on instantiated objects.
    selector: (attribute) -> "[name=#{attribute}]"

    # Dynamically selects the elements to be worked on. Can't be used until a
    # scope has been assigned.
    el: =>
        throw new Error "Axons can't use elements without scope" unless @scope
        if @selector then $(@selector, @scope) else $(@scope)

    # Fallback model attribute to sync to. By default, uses the html 'name'
    # attribute.
    attribute: (el) => el.attr 'name'

    # Fallback handler finder. By default, uses myelin.map.
    handler: (el) =>
        for [selector, handler] in myelin.map
            if el.is(selector) then return new handler {@event}
        return new Handler {@event}

    # True iff. the axon has both elements and a model to work with.
    ready: => return @scope and @model

    # A function to lazily get data that may or may not depend upon the elements
    # being synced to. For example, the model `attribute` may be a string or a
    # function that only resolves when we know the elements.
    lazy: (attr) =>
        if _.isFunction @[attr] then @[attr](@el())
        else @[attr]

    # Assign a scope from which to select elements. This should be called with
    # a view's `el`. If the synapse already had a scope (i.e. if the view is
    # changing it's `el`) then the old events will be unbound.
    assignScope: (scope) =>
        return if _.isEqual @scope, scope
        if @scope then @unbindDom()
        @scope = scope
        if @scope then @bindDom()

    # Assign a model to sync to. If the synapse already has a model (i.e. if the
    # view is switching models) then the old events will be unbound.
    assignModel: (model) =>
        return if _.isEqual @model, model
        if @model then @unbindModel()
        @model = model
        if @model then @bindModel()

    # Update the document with the model's current data. Required any time a
    # view changes model or el; updates only happen naturally on events.
    push: =>
        return unless @ready()
        value = @model.get @lazy('attribute')
        handler = @lazy('handler')
        handler.set @el(), handler.render value

    # Gets the domEvent from the handler and resolves it if necessary
    domEvent: =>
        event = @lazy('handler').domEvent
        if _.isFunction event then event @el() else event

    # Gets the modelEvent from the handler and resolves it if necessary
    modelEvent: =>
        event = @lazy('handler').modelEvent
        if _.isFunction event then event @lazy('attribute') else event

    # Sets all the DOM-side events
    bindDom: (bind='bind', delegate='delegate') =>
        event = @domEvent()
        return unless event
        if @selector then $(@scope)[delegate](@selector, event, @domChange)
        else $(@scope)[bind](event, @domChange)

    # Sets all the model-side events
    bindModel: (bind='bind') =>
        event = @modelEvent()
        return unless event
        @model[bind] event, @modelChange

    # Unbinds DOM-side events
    unbindDom: => @bindDom 'unbind', 'undelegate'

    # Unbinds model-side events
    unbindModel: => @bindModel 'unbind'

    # Called when DOM elements change. Cleans the data and sets it on the model.
    domChange: (e) =>
        return unless @model
        el = $ e.target
        handler = @lazy('handler')
        value = handler.clean handler.get el
        data = {}
        data[@lazy('attribute')] = value
        @model.set data
        if handler.preventDefault then return false

    # Called when the model changes. Renders the data and sets it on the DOM.
    modelChange: (model, value) =>
        return unless @scope
        handler = @lazy('handler')
        handler.set @el(), handler.render value


# An internal class to parse the user sync settings into an array of Axons
class Parser
    constructor: (@view) -> @axons = []

    # Break a selector into the event componet (if any) and the selector.
    # Recognized events are white-listed in myelin.events.
    normalize: (selector) =>
        if selector in myelin.events
            return event: selector, selector: false
        eventRegex = RegExp "^(#{myelin.events.join('|')})\\s+(.*)"
        match = selector.match eventRegex
        if match then return selector: match[2], event: match[1]
        return selector: selector

    # Parse any form of user-entered sync settings.
    parse: (sync) =>
        # Unroll arrays
        if _.isArray sync then _.map sync, @parse
        # Axon instances are already done
        else if sync instanceof Axon then @axons.push sync
        # Resolve functions with the view as their context
        else if _.isFunction sync then @parse sync.call @view
        # If they gave us just `string`, interpret it as a selector
        else if _.isString sync then @axons.push new Axon @normalize sync
        # If they gave an object, parse each key-value pair
        else @parsePair(key, value) for key, value of sync
        return this

    # Parse a {attribute: selector or handler} pair into a Synapse.
    parsePair: (attr, option) =>
        # Helper to make a new Axon with attribute: attr
        make = (options={}) =>
            options.attribute or= attr
            @axons.push new Axon options
        # A falsy `option` means 'ignore this attribute'.
        # Allows resolved functions to say 'never mind'.
        if (not option) then return
        # {attr: true} means 'make an axon with no selector'
        else if option is true then make()
        # Given an array of selectors, make a synapse for each one.
        else if _.isArray option then @parsePair(attr, o) for o in option
        # Given a handler class, we instantiate it and use it
        else if isHandlerClass option then make handler: option
        else if option instanceof Handler then make handler: option
        else if option instanceof Axon
            option.attribute = attr
            @axons.push option
        # If `option` is a non-axon function, resolve it with the view as the
        # context and the selector as an argument.
        else if _.isFunction option
            @parsePair attr, option.call(@view, attr)
        # If `option` is a selector, make sure to split off any event first
        else if _.isString option then make @normalize option
        # Otherwise try passing the arguments to axon
        else if _.isObject option then make option
        # Complain if the attr wasn't valid.
        else throw new Error "Unrecognized sync option for #{attr}: #{option}"
        return this


# The myelin view. Makes axons based on the @sync field in order to sync
# between the DOM and models. @sync can be a number of types
#
# ## @sync types:
#   * Array
#       Each element in the array must be one of these sync types
#   * String
#       Interpreted as an attribute name. An appropriate selector will be found
#       using myelin.selector, and an appropriate axon will be selected using
#       axon.map and axon.default.
#   * Axon class or instance
#       The axon class will be instantiated (if necessary) and will not be given
#       a selector nor attribute. It had better have one or the other, or it
#       will be quite difficult for the axon to figure out what to watch.
#   * Function
#       Called with the view as it's context. The result is recursively parsed.
#   * Object
#       The object key must be the model attribute to be synced to
#       The model value may be any one of the @sync object values below
#
# ## @sync object values
#   * false (or any falsy value)
#       A key with a false value will be ignored
#   * true
#       A key with a true value will look up the axon and selector to use at
#       event time, using myelin.lookup, myelin.dynamic, and myelin.selector
#   * Array
#       {key: [val1, val2]} is identical to {key: val1, key: val2}
#   * String
#       String values represent an object selector. They can optionally be
#       preceded with any event in myelin.events (the jQuery event list by
#       default) to override Axon.event.
#   * Axon class
#       The given axon class will be instantiated and used to handle events.
#   * Axon instance
#       The given axon will be used to handle events.
#   * Function
#       Will be resolved with the view as the context and the attribute as an
#       argument, then recursively re-parsed.
class View extends Backbone.View
    constructor: ->
        super
        @axons = (new Parser).parse(@sync).axons
        @delegateLinks()

    delegateLinks: (options) =>
        @model = options?.model or @model
        @el = options?.el or @el
        for axon in @axons
            if @el then axon.assignScope(@el)
            if @model then axon.assignModel(@model)
            if @el or @model then axon.push()

# Expose myelin.View as Backbone.SyncView for simplicity.
myelin.View = Backbone.SyncView = View

# A list used to intelligently match axons to elements.
# Each element in myelin.map should be a [selector, axon] two-tuple.
# If an element matches `selector` (using .is()) then `axon` will be used for
# that element.  Order matters; the first match is used.
# Override myelin.map to change the default axon matching.
myelin.map = [
    ['a', Link]
    ['input:submit,button:submit', Submit]
    ['button,input:button', Button]
    ['input:checkbox', Checkbox]
    ['input:radio', Radio]
    # Uncomment to enable the Password axon
    # ['input:password', Password]
    ['select,input,textarea', Input]
]

myelin.Axon = Axon

handlers = {Handler, Link, Input, Button, Submit, Checkbox, Radio, Password}
_.extend myelin, handlers
