# Save a reference to the global object
root = this

# Save a reference to the current myelin object
previousMyelin = root.myelin

# Create the myelin object in the global namespace
if typeof exports isnt 'undefined' then myelin = exports
else myelin = root.myelin = {}

# require underscore, if we're on the server, and if it's not already present.
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
# myelin whitelists events instead of blacklisting tags to that you can include
# weird tags from non-html documents such as SVG or custom XML.
# Event class names (such as keyUp.myEvent) are recognized so long as the part
# before the dot is in myelin.events.
myelin.events = [
    'blur', 'focus', 'focusin', 'focusout', 'load', 'resize', 'scroll'
    'unload', 'click', 'dblclick', 'mousedown', 'mouseup', 'mousemove'
    'mouseover', 'mouseout', 'mouseenter', 'mouseleave', 'change', 'select'
    'submit', 'keydown', 'keypress', 'keyup', 'error'
]

# A class that handles all interaction between the DOM and the Model.
class Handler
    # For convenience, the constructor can take an 'event' option which, if
    # present, overrides domEvent.
    constructor: (options) -> if options?.event? then @domEvent = options.event

    # Get the value from the DOM element
    get: (el) -> el.html()

    # Clean the value for sending to the model
    clean: (value) -> value

    # Prepare the model's value for display
    render: (value) -> value

    # Set the model's value on the DOM element
    set: (el, value) -> el.html value

    # The event to listen for on the DOM element, or falsy if the model does not
    # listen to the DOM
    domEvent: false

    # The event to listen for on the model, or falsy if the DOM does not listen
    # to the model
    modelEvent: (attribute) -> "change:#{attribute}"

    # Whether or not the default DOM event should be stifled
    preventDefault: false

# A handler that gets and sets using jQuery .val()
class Input extends Handler
    domEvent: 'change'
    get: (el) -> el.val()
    set: (el, value) -> el.val value

# An input handler that syncs on keyup
class ImmediateInput extends Input
    domEvent: 'keyup'

# An Input handler that responds to click events and ignores the model
# The common use pattern for buttons is to have a number of buttons with
# different values, and clicking each button sets that button's value on the
# model. As such, buttons must ignore changes on the model, or all of the
# buttons will sync to the model the moment one of them is clicked.
class Button extends Input
    domEvent: 'click'
    modelEvent: false
    get: (el) ->
        if el.is('button') then el.html() else el.val()
    set: (el, value) ->
        if el.is('button') then el.html(value) else el.val(value)

# An Input handler for submit buttons. It works just like Button, but also
# prevents the default DOM event, which would submit a form.
class Submit extends Button
    preventDefault: true

# An Input button for checkboxes. It `get`s a boolean value and `set`s the
# checkbox's "checked" attribute.
class Checkbox extends Input
    get: (el) -> el.is ':checked'
    set: (el, value) ->
        if value then el.attr('checked', 'checked') else el.removeAttr 'checked'
    clean: Boolean
    render: Boolean

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


# The Axon class preforms the binding between the element and the model.
class Axon
    # Axons take four options in the constructor:
    # __selector__, __attribute__, __handler__, and __event__.
    constructor: (options={}) ->
        # `attribute` is inferred from `selector` at event time if absent
        if options.attribute then @attribute = options.attribute

        # `selector` is inferred immediately from `attribute` if absent
        if options.selector then @selector = options.selector
        else @selector = @selector @attribute

        # Outside of an axon, the _this_ selector means _link the view's `el`_
        # Inside of an axon, a false selector means the same thing.
        if @selector is 'this' then @selector = false

        # `handler` is inferred from `myelin.handlerMap` at event time if absent.
        if options.handler instanceof Handler then @handler = options.handler
        # If `handler` is a class, we instantiate it immediately.
        else if isHandlerClass options.handler then @handler = new options.handler
        # If it's not a handler or a handler class, assume it's a handler function
        else if options.handler then @handler = options.handler

        # We override the handler's domEvent if asked nicely.
        if options.handler instanceof Handler and options.event?
            @handler.domEvent = options.event
        # If only an event is given we save it for when we dynamically choose
        # a handler.
        else if options.event? then @event = options.event

        @scope = @model = null

    # This selector function will never be present on an instantiated Axon.
    # If `selector` is ommited when declaring an Axon, this function will be
    # called immediately to determine the correct selector.
    selector: (attribute) -> "[name=#{attribute}]"

    # Fallback model attribute. By default, uses the html 'name' attribute.
    # Called at event time. If the elements change their 'name' attribute
    # in between events, then the model attribute synced will change to match.
    # `el` will be jQuery wrapped.
    attribute: (el) => el.attr 'name'

    # Fallback handler finder. By default, uses myelin.handlerMap, and falls
    # back to myelin.defaultHandler.
    # Called at event time. If the elements change their type from, say,
    # checkbox to radio in between events then the handler will change to match.
    # `el` will be jQuery wrapped.
    handler: (el) =>
        for [selector, handler] in myelin.handlerMap
            if el.is(selector) then return new handler {@event}
        return new myelin.defaultHandler {@event}

    # Dynamically selects the elements to be worked on. Can't be used until a
    # scope has been assigned.
    el: =>
        throw new Error "Axons can't use elements without scope" unless @scope
        if @selector then $(@selector, @scope) else $(@scope)

    # True iff. the axon has both elements and a model to work with.
    ready: => return @scope and @model

    # A function to lazily get data that may or may not depend upon the elements
    # being synced to. For example, the model `attribute` may be a string or a
    # function that only resolves when we know the elements.
    # All attributes that are found to be functions will be resolved with @el()
    # as their first parameter, and any additional arguments to `lazy` as
    # additional parameters.
    lazy: (attr, args...) =>
        if _.isFunction this[attr] then this[attr](@el(), args...)
        else this[attr]

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
    # view changes model or el; updates only happen automatically on events.
    # If `modelEvent` is falsy, no changes will be made, because the model does
    # not push to the document.
    push: =>
        return unless @ready() and @modelEvent()
        value = @model.get @lazy 'attribute'
        handler = @lazy 'handler', @event
        handler.set @el(), handler.render value

    # Gets the domEvent from the handler and resolves it if necessary
    # handler.domEvent is either a value or a function that takes the elements
    # being linked.
    domEvent: =>
        event = @lazy('handler', @event).domEvent
        if _.isFunction event then event @el() else event

    # Gets the modelEvent from the handler and resolves it if necessary
    # handler.modelEvent is either a value or a function that takes the
    # attribute being linked.
    modelEvent: =>
        event = @lazy('handler', @event).modelEvent
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
        handler = @lazy 'handler', @event
        value = handler.clean handler.get el
        data = {}
        data[@lazy 'attribute'] = value
        @model.set data
        if handler.preventDefault then return false

    # Called when the model changes. Renders the data and sets it on the DOM.
    modelChange: (model, value) =>
        return unless @scope
        handler = @lazy 'handler', @event
        handler.set @el(), handler.render value


# An internal class to parse the user sync settings into an array of Axons
class Parser
    constructor: (@view) -> @axons = []

    # Break a selector into the event componet (if any) and the selector.
    # Recognized events are white-listed in myelin.events.
    # Events with classes (i.e. keyup.MyEvent1.MyEvent2) are also recognized.
    normalize: (selector) =>
        if selector in myelin.events
            return event: selector, selector: false
        eventRegex = RegExp "^((?:#{myelin.events.join('|')})(?:\\.\\S+)*)\\s+(.*)"
        match = selector.match eventRegex
        if match then selector: match[2], event: match[1]
        else selector: selector

    # Parse any form of user-entered sync settings.
    parse: (sync) =>
        # Unroll arrays
        if _.isArray sync then _.map sync, @parse
        # Axon instances are already done
        else if sync instanceof Axon then @axons.push sync
        # Resolve functions with the view as their context
        else if _.isFunction sync then @parse sync.call @view
        # If they gave us just `string`, interpret it as a {string: true}
        else if _.isString sync then @parsePair sync, true
        # If they gave an object, parse each key-value pair
        else @parsePair(key, value) for key, value of sync
        return this

    # Parse a {attribute: selector or handler} pair into a Synapse.
    parsePair: (attr, option) =>
        # Helper to make a new Axon with attribute: attr
        make = (options={}) =>
            options.attribute or= attr
            @axons.push new myelin.axon options
        # A falsy `option` means 'ignore this attribute'.
        # Allows resolved functions to say 'never mind'.
        if (not option) then return
        # {attr: true} means 'make an axon with no selector'
        else if option is true then make()
        # Given an array of selectors, make a link for each one.
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
            @parsePair attr, option.call @view, attr
        # If `option` is a selector, make sure to split off any event first
        else if _.isString option then make @normalize option
        # Otherwise try passing the arguments to axon
        else if _.isObject option then make option
        # Complain if the attr wasn't valid.
        else throw new Error "Unrecognized sync option for #{attr}: #{option}"
        return this


# The myelin view. Makes axons based on the `sync` field in order to sync
# between the DOM and models. `sync` can be a number of types. See README.md
# for more details.
class View extends Backbone.View
    constructor: (options) ->
        if options.model then @model = options.model
        super
        @link()

    link: (options) =>
        @axons = (new Parser).parse(@sync).axons
        @model = options?.model or @model
        @el = options?.el or @el
        for axon in @axons
            if @el then axon.assignScope(@el)
            if @model then axon.assignModel(@model)
            axon.push()

# A list used to intelligently match handlers to elements.
# Each element in myelin.handlerMap should be a [selector, handler] two-tuple.
# If an element matches `selector` (using .is()) then `handler` will be used for
# that element. Order matters; the first match is used.
myelin.handlerMap = [
    ['input:submit,button:submit', Submit]
    ['button,input:button', Button]
    ['input:checkbox', Checkbox]
    ['input:radio', Radio]
    ['textarea', ImmediateInput]
    ['select,input', Input]
]

# The default handler to be used when no suitable handler can be found.
myelin.defaultHandler = Handler

# Expose the handlers
handlers = {Handler, Input, Button, Submit, Checkbox, Radio, Password}
_.extend myelin, handlers

# Expose the Axon class
myelin.Axon = Axon

# The default axon to be used for all bindings. If you subclass Axon and
# want the default behavior to be changed, override myelin.axon as well.
myelin.axon = Axon

# Expose myelin.View
myelin.View = View
