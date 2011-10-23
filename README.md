Myelin automates the linking of your HTML elements to your Backbone Models,
through your Backbone Views. All you need to do is use myelin.View instead
of Backbone.View, and declare a 'sync' attribute on your view, like this:

    class MyView extends myelin.View
        sync:
            user: 'input[name=user]'
            message: '#message'

Then, if you have HTML like this:

    <form id="myForm">
        <input name="user">
        <span id="message"></span>
    </form>

And a model like this:

    model = new Backbone.Model message: "Hello, world!"

And a view like this:

    view = new MyView {el: '#myForm', model}

Then the view will link the form to the model. Any changes to the "user" input
field will update the "user" attribute on the model, and any change to the
"message" attribute of the model will be reflected in the message span.

__Quick Tip__

The {attr: [name=attr]} sync pattern is so common that you can use the shortcut
{attr: true}. It means the same thing. So, for example, the above model could be
reduced to

    class MyView extends myelin.View
        sync:
            user: true
            message: '#message'

## Quickly now

If you're the impatient type, you might want to jump directly to some
[[examples]], or perhaps the [[annotated source]].

## Quickly now

If you're the impatient type, you might want to jump directly to some
[examples], or perhaps the [annotated source]. (links forthcoming)

# How to Use

Myelin is used by creating myelin Views with a `sync` property that controls
how objects are linked. Before linking can be done, views must also have both
an `el` property and a `model` property set. You are welcome to set these
any time after view creation and change them on the fly, so long as you call
view.link() any time you change `el` or `model`.

The `sync` property describes links between forms and models in a number of
formats. Before we go over the different formats for links, you must understand
how links works. Each link consists of three parts: an __attribute__, a
__selector__, and a __handler__.

## Attributes

Attributes are the most simple component of a link. They are simply a string
naming the attribute on the model that you want to sync your data to. If a
string isn't quite flexible enough, you can also provide a function that takes
the DOM elements being linked and returns the attribute to sync to at
event-time. If the attribute is omitted then a fallback function (that depends
upon the selector) will be used. Because attribute functions depend upon the
elements being synced, if the attribute is a function then the selector _must_
be provided as a string.

The fallback function returns the "name" attribute of the elements being linked.
For example, if you link create a link to an element `<input name="test">` and
you don't provide an attribute, the element will be synced to the `test`
attribute.

## Selectors

Selectors are simply a jQuery selector used to select the elements being linked.
The actual elements will be selected as late as possible, in the context of the
view's `el`. Thus, if you dynamically add or remove elements that match the
selector to the view, the elements will automatically be linked.

If you want to bind to the actual view `el` (instead of the view's children),
use the special 'this' selector.

You may also provide a function to determine the selector; this function will
be called with the `attribute` of the link. If the selector is a function then
an attribute _must_ be provided.

The fallback function selects elements with the same name as the attribute.
For example, if you create a link to the attribute 'user', then the selector
`name="user"` will be linked.

## Handlers

Handlers bridge the gaps between DOM elements and model attributes. At their
core, handlers preform four actions:

 * __get__ data from an element
 * __clean__ element data for a model
 * __render__ model data for an element
 * __set__ rendered data on an element

The also control the linking in three ways:

 * __domEvent__
    - controls the DOM event that triggers syncing
    - if falsy then the model will not respond to DOM changes
    - can be a function which will be passed the elements being synced
 * __modelEvent__
    - controls the model event that triggers syncing
    - if falsy then the DOM will not respond to model changes
    - can be a function which will be passed the attribute being synced
 * __preventDefault__
    - controls whether or not the default DOM event is prevented

Handlers can always be left out of a link, in which case they will be inferred
from the elements being bound using myelin.handlerMap and myelin.defaultHandler.

A handful of handlers come built in to Myelin. You can provide your own handlers
to customize data manipulation. The built in handlers are as follows:

### Handler

The default handler is used for divs, spans, and other elements that don't take
user input. It works as follows:

  * __get__ accesses inner html
  * __set__ sets inner html
  * __clean__ performs no action
  * __render__ performs no action
  * __domEvent__ is false, as these elements never change on their own
  * __modelEvent__ returns "change:#{attribute}"
  * __preventDefault__ is false

### Input

A Handler used for most inputs. `get`s and `set`s using jQuery's .val().
`domEvent` is "change", meaning the model will be synced whenever a "change"
event is fired. Used by default for input and select elements.

### ImmediateInput

An Input that syncs on "keyup" instead of "change". Used by default for
textareas.

### Button

Like Input, but `domEvent` is "click" and `modelEvent` is `false`. Buttons, by
default, do not update to match model attributes.

### Submit

Like Button, but prevents the default DOM event from being fired.

### Checkbox

An Input handler that handles checking and unchecking its element. Note that
`render` and `clean` will both convert their values to Booleans.

### Radio

An Input handler that handles selecting the correct radio element. The selector
should match a whole set of radio buttons. `get` will return the value of the
checked button, and `set` will ensure that only the button with the matching
value is checked.

### Password

An Input handler that encrypts its data before setting it on the model. Useful
if your model auto-syncs with a server. Not enabled by default, because the
syncing causes the length of the password to change, which can be disconcerting.
You can enable it if you like, but you probably shouldn't be syncing passwords
with models automatically.

## Specifying Links

In order to specify a link, you must specify the attribute, handler, and
selector that you would like to use. Any of these can be left out, but if you
leave out the attribute then you have to provide a selector, and visa versa.

Links are specified on the `sync` attribute of a view. Usually, `sync` is an
object, but it can also be a single item or a list of items: see the shorthand
section below.

### The Sync object

Sync objects are given in the form
    
    attribute: specification

Where specification can take the following forms:

  * false
    - if the specification is false then the attribute will be ignored.
      This allows specification functions to essentially say 'never mind'.
  * true
    - if the specification is true then a link will be made where both the
      handler and selector are omitted.
  * array
    - given {attr: [selector1, selector2]}, the links `attr: selector1` and
      `attr: selector2` will be created.
  * function
    - the function will be resolved with the view as it's context and the
      attribute as a parameter. The result will be parsed recursively.
  * handler class
    - a link will be made between the attribute and an instantiated version
      of the handler class. The selector will be omitted.
  * handler instance
    - a link will be made between the attribute and the handler. The
      selector will be omitted.
  * string
    - treated as a selector. A link will be made with the handler omitted.
  * object
    - an object can be passed with 'handler', 'selector', and optionally
      'event' properties, which will all be used to make the link.

#### Convenient Events

A selector string can be given in the form "event selector" (a jQuery event
separated from the selector by whitespace). In this case, the event will be
split off from the selector and will override handler.domEvent. For example,

    {name: "keyup [name=firstname]"}

will create a link between the attribute 'name' and the selector
'[name=firstname]'. An Input handler will be used, but the handler will listen
for the 'keyup' event instead of the usual 'change' event.

You can also provide an 'event' property in a specification as follows:

   {name: {selector: "[name=firstname]", event: "keyup"}}

for the same effect. Recognized events are whitelisted in myelin.events.

#### Shorthand

If you want to be even more terse, sync doesn't need to be an object. It can
also be an array or a string.

    sync: ["first_name", "last_name"]

is identical to

    sync: {first_name: true, last_name: true}

You can also provide [[Axon]] instances directly, though that's only recommended
for advanced users.

# Under the Hood

Under the hood, myelin uses a class called Axon to manage links. An axon takes
four parameters in an object in the constructor. They are:
    * attribute
    * selector
    * handler
    * event

`event`, if given, overrides handler.domEvent. See the [[annotated source]] for
more details.

# Configuration

Myelin can be configured in a variety of ways:

## Changing Handler assignment

If you want to change the default handlers, override `myelin.handlerMap`.
`myelin.handlerMap` is a list of (selector, handler) two-tuples that determine
which handler is used for which selector (if no handler is specified).
Handlers are matched from top to bottom, and if no match is found then
`myelin.defaultHandler` is used instead.

## Changing the fallback attribute

If an attribute is omitted, it is determined using the Axon.attribute function,
which takes the linked elements and returns the model attribute to sync to.
To change this behavior, override Axon.attribute.

## Changing the fallback selector

If a selector is omitted, it is determined using the Axon.selector function,
which takes the model attribute and returns a selector.
To change this behavior, override Axon.selector.

## Changing Axon

If you find yourself overriding a number of Axon functions, it may be easier
to subclass Axon and simply tell myelin to use a different Axon class. To
do this, simply set `myelin.axon` to your Axon class. Note that your custom
axon must be a child of myelin.Axon if you want things to work properly.

# Resources

[[backbone.js]]
[[coffeescript]]
[[underscore.js]]
