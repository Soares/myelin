# This is a handler, used to specify complex behavior.
# This one uppercases incoming model data, and pushes
# the uppercased data on click events.
# We'll be using it for the cyan span.
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
      {handler: UpperHandler, selector: 'span.cyan'}
    ]

# The view must have both 'el' and 'model'.
new IntroView el: '#intro', model: new Backbone.Model
