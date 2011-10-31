# This is a handler, used to specify complex behavior.
# We'll be using this one for the blue button.
class Uppercaser extends myelin.Button
  clean: (str) -> str?.toUpperCase()

# A myelin.View is a Backbone.View with a 'sync' field.
# The 'sync' specifies how we link documents to models.
class IntroView extends myelin.View
  sync:
    field: [            # sync to the 'field' attribute
      'keyup input.red' # use keyup for the red input
      'input.green'     # use the defaults for green
      {selector: 'button.blue', handler: Uppercaser}
      'span.cyan'       # use the defaults for cyan
    ]

# The view must have both 'el' and 'model'.
@introModel = new Backbone.Model
@introView = new IntroView el: '#intro', model: introModel
