# Save a reference to the global object
root = this
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
# to its previous owner. Returns a reference to this myelin object.
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

# The default event to watch for on DOM elements
myelin.event = 'change'

# Axons are the 'controllers' that handle linking backbone models to views.
# Each axon must know how to get and set data from the DOM and how to clean
# data for the model and render data from the model.
# The default axon gets data from and sets data to an element's inner html,
# using jQuery's html() function.
#
# Optionally, an axon can have a few other parameters that affect how the
# syncing is done.
#
# ## Axon Options
#   @event:         the event that the sync will be fired on.
#                   By default, this will be 'change'.
#                   The default can be changed by overriding myelin.event
#   @attribute:     the name of the attribute to set on the model.
#                   This may be a function, in which case it must take one
#                   parameter, which is the ($-wrapped) element being synced.
#   @watchDom:      Whether or not the axon responds to DOM events.
#   @watchModel:    Whether or not the axon responds to model events.
#
#   By default
#       `event` is undefined,
#       `attribute` is set via the constructor,
#       `watchDom` is true,
#       `watchModel` is true.
class myelin.Axon
    constructor: (@attribute=null) ->

    # Get the value from the DOM element
    get: (el) -> el.html()

    # Clean the value for sending to the model
    clean: (value) -> value

    # Prepare the model's value for display
    render: (value) -> value

    # Set the value on the DOM element
    set: (el, value) -> el.html value

    # Whether or not to watch DOM events
    watchDom: true

    # Whether or not to watch Model events
    watchModel: true

# An axon that responds to click events
class myelin.Link extends myelin.Axon
    event: 'click'

# An axon that gets and sets data using jQuery's val()
class myelin.Input extends myelin.Axon
    event: 'change'
    get: (el) -> el.val()
    set: (el, value) -> el.val value

# An Input axon that responds to click events.
class myelin.Button extends myelin.Input
    event: 'click'

# An Input axon that responds to submit events.
class myelin.Submit extends myelin.Input
    event: 'submit'

# An Input button for checkboxes. It `get`s a boolean value and `set`s the
# checkbox's checked attribute.
class myelin.Checkbox extends myelin.Input
    get: (el) -> el.is 'checked'
    set: (el, value) ->
        if value then el.attr('checked', 'checked') else el.removeAttr 'checked'

# An Input axon for radio fields. For this axon, `el` will be a collection of
# elements in the radio set. `get` will return the value of the checked field,
# and `set` will cause only the field with the matching value to be checked.
class myelin.Radio extends myelin.Input
    get: (el) -> el.filter(':checked').val()
    set: (el, value) ->
        el.removeAttr 'checked'
        el.filter("[value=#{value}]").attr 'checked', 'checked'

# An Input axon for password fields. The user-entered password will never get
# sent to the model, a bcrypt-encrypted hash will be sent instead. This helps
# developers remember to never send unencrypted passwords across the line, and
# is absolutely essential with tools like spine that auto-sync model data with
# the server.
# This Axon isn't used by default, as it will alter the length of the password
# that displays on the input field.
class myelin.Password extends myelin.Input
    clean: (value) ->
        bcrypt = require 'bcrypt'
        salt = bcrypt.gen_salt_sync
        bcrypt.encrypt_sync value, salt

# A list used to intelligently match axons to elements.
# Each element in myelin.map should be a [selector, axon] two-tuple.
# If an element matches `selector` (using .is()) then `axon` will be used for
# that element.  Order matters; the first match is used.
# Override myelin.map to change the default axon matching.
myelin.map = [
    ['a', myelin.Link]
    ['input:submit,button:submit', myelin.Submit]
    ['button', myelin.Button]
    ['input:checkbox', myelin.Checkbox]
    ['input:radio', myelin.Radio]
    # Uncomment to enable the Password axon
    # ['input:password', myelin.Password]
    ['select,input,textarea', myelin.Input]
]

# The default axon to use if an appropriate axon is not found in myelin.map
myelin.default = myelin.Axon

# When an axon doesn't know the model attribute to sync to, it uses
# myelin.attribute to look it up. myelin.attribute will be called at event-time
# with the element being synced as a parameter.
# The parameter will be $-wrapped.
# By default, el.attr('name') will be used.
myelin.attribute = (el) -> el.attr 'name'

# When a sync is defined using only an attribute, myelin.selector is called to
# determine the selector to match the attribute. 
# By default, this is any alement with a name that matches the attribute.
myelin.selector = (attribute) -> "[name=#{attribute}]"

# Used intertally to see if something is an axon.
# Guesses by duck-typing the prototype.
isAxonClass = (fn) ->
    return (_.isFunction fn) and
           (fn::) and (fn::constructor) and
           (fn::get) and (fn::set) and
           (fn::clean) and (fn::render)

# An internal structure that does all the event binding and unbinding so that
# developers can keep their axons simple and not see the man behind the curtain.
# Synapses can take a number of parameters in their 'options' argument
#   @selector:      The selector to use to determine the elements to bind to.
#                   This selector will be looked up in the scope of the view's
#                   `el`. Furthermore, all events will be delegated instead of
#                   bound if possible, so dynamically added elements don't have
#                   to be watched for. If `selector` is falsy or the string
#                   'this', then the view's `el` will be used.
#   @axon:          The axon to use. If unspecified, the axon will be looked up
#                   at binding time using myelin.map and myelin.default 
#   @event:         The DOM event to bind to. Overrides @axon.event if given.
#   @attribute:     The attribute to sync. Overrides @axon.attribute if given.
class Synapse
    constructor: (options) ->
        options = options or {}
        @scope = @model = null
        @selector = options.selector
        if @selector is 'this' then @selector = false
        @axon = options.axon
        @detectAxon = not options.axon

        @event = options.event or @axon?.event or false
        @attribute = options.attribute or @axon?.attribute or false

        @assignScope(options.scope) if options.scope
        @assignModel(options.model) if options.model

        @push()

    # Dynamically select an axon that works for @el
    chooseAxon: =>
        el = @el()
        for [selector, axon] in myelin.map
            if el.is(selector) then return new axon
        return new myelin.default

    # True iff. the synapse has both elements and a model to work with.
    ready: => return @scope and @model

    # Lazily selects the elements being affected so as to include dynamically
    # added elements
    el: => if @selector then $(@selector, @scope) else $(@scope)

    # Lazily determines the attribute to sync to so as to include data from
    # dynamically added elements
    attr: =>
        attr = @attribute or @axon.attribute or myelin.attribute
        if _.isFunction attr then attr @el() else attr

    # Assign a scope from which to select elements. This should be called with
    # a view's `el`. If the synapse already had a scope (i.e. if the view is
    # changing it's `el`) then the old events will be unbound.
    assignScope: (scope) =>
        return if _.isEqual @scope, scope
        if @scope then @unbindDom()
        @scope = scope
        if @detectAxon then @axon = (if @scope then @chooseAxon() else null)
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
        @axon.set @el(), @axon.render @model.get @attr()

    # Sets all the DOM-side events
    bindDom: (bind='bind', delegate='delegate') =>
        return unless @axon.watchDom
        event = @event or @axon.event or myelin.event
        $(@scope)[bind](event, @domChange) unless @selector
        $(@scope)[delegate](@selector, event, @domChange) if @selector

    # Sets all the model-side events
    bindModel: (bind='bind') =>
        return unless @axon.watchModel
        @model[bind] "change:#{@attr()}", @modelChange

    # Unbinds DOM-side events
    unbindDom: => @bindDom 'unbind', 'undelegate'

    # Unbinds model-side events
    unbindModel: => @bindModel 'unbind'

    # Called when DOM elements change. Cleans the data and sets it on the model.
    domChange: (e) =>
        return unless @model
        el = $ e.target
        value = @axon.clean @axon.get el
        data = {}
        data[@attr()] = value
        @model.set data

    # Coled when the model changes. Renders the data and sets it on the DOM.
    modelChange: (model, val) =>
        return unless @scope
        @axon.set @el(), @axon.render val

# An internal class to parse the user-inputed sync settings into an array
# of Synapses
class Parser
    # Any options given in @options will be passed along to the Synapse
    # constructor.
    constructor: (@view, @options) ->
        @synapses = []

    # Break a selector into the event componet (if any) and the selector.
    # Recognized events are white-listed in myelin.events.
    normalize: (selector) =>
        eventRegex = RegExp "^(#{myelin.events.join('|')})\\s+(.*)"
        match = selector.match eventRegex
        if match then return selector: match[2], event: match[1]
        return selector: selector

    # Parse any form of user-entered sync settings.
    parse: (sync) =>
        # Unroll arrays
        if _.isArray sync then _.map sync, @parse
        # Instantiate axon classes
        else if isAxonClass sync then @make axon: new sync
        # Send axons off without selectors
        else if sync instanceof myelin.Axon then @make axon: sync
        # Resolve functions with the view as their context
        else if _.isFunction sync then @parse sync.call @view
        # If they gave us just `string`, interpret it as an attribute
        # and generate the selector using myelin.selector
        else if _.isString sync then @parsePair sync, (myelin.selector sync)
        # If they gave an object, parse each key-value pair
        else if sync then @parsePair(key, value) for key, value of sync
        return this

    # Parse a {attribute: selector or axon} pair into a Synapse.
    parsePair: (attr, option) =>
        # A helper function to call the synapse maker function with
        # attribute: attr set automatically
        make = (ops) => @make _.extend attribute: attr, ops
        # A falsy `option` means 'ignore this attribute'.
        # Allows resolved functions to say 'never mind'.
        if (not option) then return
        # {attr: true} means 'look the selector up at event time'.
        # To a synapse, this is the same as a missing selector
        else if option is true then make()
        # Given an array of selectors, make a synapse for each one.
        else if _.isArray option then @parsePair(attr, o) for o in option
        # Given an axon class, we instantiate it and use it to make a synapse.
        else if isAxonClass option then make axon: new option
        # Given an axon instanceo, we use it to make a synapse
        else if option instanceof myelin.Axon then make option
        # If `option` is a non-axon function, resolve it with the view as the
        # context and the selector as an argument.
        else if _.isFunction option
            @parsePair attr, option.call(@view, attr)
        # If `option` is a selector, make sure to split off any event first
        else if _.isString option then make @normalize option
        # Complain if the attr wasn't valid.
        else throw new Error "Unrecognized sync option for #{attr}: #{option}"
        return this

    # Creates a synapse from `selector` and `desc`. `desc` can be anything that
    # makes it through @valid.
    make: (options) =>
        @synapses.push new Synapse options
        return this


# The myelin view. Makes synapses based on the @sync field in order to sync
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
#       event time, using myelin.lookup, myelin.default, and myelin.selector
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
class myelin.View extends Backbone.View
    constructor: ->
        super
        @synapses = (new Parser).parse(@sync).synapses
        @delegateLinks()

    delegateLinks: (options) =>
        @model = options?.model or @model
        @el = options?.el or @el
        for synapse in @synapses
            if @el then synapse.assignScope(@el)
            if @model then synapse.assignModel(@model)
            if @el or @model then synapse.push()

# Expose myelin.View as Backbone.SyncView for simplicity.
Backbone.SyncView = myelin.View
