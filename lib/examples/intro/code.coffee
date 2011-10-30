# This is a handler, used to specify complex behavior.
# We'll be using this one for the cyan span.
class UpperHandler extends myelin.Handler
  render: (str) -> str?.toUpperCase()
  domEvent: 'click'

# A myelin.View is a Backbone.View with a 'sync' field.
# The 'sync' specifies how we link documents to models.
class IntroView extends myelin.View
  sync:
    field: [            # sync to the 'field' attribute
      'keyup input.red' # use keyup for the red input
      'input.blue'      # use the default input handler
      'span.amber'      # use the default span handler
      {selector: 'span.cyan', handler: UpperHandler}
    ]

# The view must have both 'el' and 'model'.
new IntroView el: '#intro', model: new Backbone.Model
