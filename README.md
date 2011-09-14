Myelin automates the linking of your HTML elements to your Backbone Models,
through your Backbone Views. All you need to do is use myelin.View instead
of Backbone.View, and declare a 'sync' attribute on your view, like this:

    class MyView extends myelin.View
        sync:
            user: 'input[name=user]'
            message: '#message'

Then, if you have HTML like this:

    <form id="myForm">
        <input name="name">
        <span id="message"></span>
    </form>

And you make a view like this:

    model = new Backbone.Model message: "Hello, world!"
    view = new MyView {el: '#myForm', model}

Then your input and span are now linked to your model. Any changes to the input
will be reflected on the model. Any changes to the model's "user" attribute will
be reflected on the input. Finally, any change to the model's "message"
attribute will be reflected on the span.

### Quick Tip

The {attr: [name=attr]} sync pattern is so common that you can use the shortcut
{attr: true}. It means the same thing.

## Quickly now

If you're the impatient type, you might want to jump directly to some
[examples], or perhaps the [annotated source]. (links forthcoming)

# How to Use

Myelin is used by creating myelin Views with a `sync` property that controls
how objects are linked. Before linking can be done, views must also have both
an `el` property and a `model` property set. You are welcome to set these
any time after view creation and change them on the fly, so long as you call
View.link() any time you change `el` or `model`.

The `sync` property describes links in a number of formats. Before we go over
them all, you have to understand how a link works. Each link consists of three
major parts: an __attribute__, a __selector__, and a __handler__.

## Attributes

Attributes are the most simple component of a link. They are simply a string
naming the attribute on the model that you want to sync your data to. If a
string isn't quite flexible enough, you can also provide a function that takes
the DOM elements being linked and returns the attribute to sync to at
event-time. If the attribute is omitted then a fallback function (that depends
upon the selector) will be used. Because attribute functions depend upon the
elements being synced, if the attribute is omitted or is a function then the
selector _must_ be provided as a string.

The fallback function returns the "name" attribute of the elements being linked.
To change the fallback function, see the Axon section below.

## Selectors

Selectors are simply a jQuery selector used to select the elements being linked.
The actual elements will be selected as late as possible, in the context of the
view's `el`. Thus, if you dynamically add or remove elements that match the
selector to the view, the elements will automatically be linked.

If you want to bind to the actual view `el` (instead of the view's children),
use the special 'this' selector.

You may also provide a function to determine the selector; this function will
be called with the `attribute` of the link. If the selector is omitted or is
a function then an attribute _must_ be provided.

The fallback function selects elements with the same name as the attribute.
To change the fallback function, see the Axon section below.

## Handlers

Handlers bridge the gaps between DOM elements and model attributes. At their
core, handlers preform four actions:

 * __get__ data from an element
 * __clean__ element data for a model
 * __render__ model data for an element
 * __set__ rendered data on an element

The also control the events in three ways:

 * __domEvent__
    - controls the DOM event that triggers syncing
    - if falsy then the model will not respond to DOM changes
    - can be a function taking the elements being bound
 * __modelEvent__ controls the model event that triggers syncing
    - controls the model event that triggers syncing
    - if falsy then the DOM will not respond to model changes
    - can be a function taking the attribute being synced
 * __preventDefault__
    - controls whether or not the default DOM event is prevented

Handlers can always be left out of a link, in which case they will be inferred
from the elements being bound using myelin.map and myelin.handler (see below).

A handful of handlers come built in to Myelin. If you want to provide custom
data manipulation, cleaning, or rendering then extend one of these handlers.

### Handler

The default handler is used for divs, spans, and other elements that don't take
user input. It works as follows:

  * __get__ accesses inner html
  * __set__ sets inner html
