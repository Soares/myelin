input '.red', placeholder: 'start typing...', ->
small ->
	text 'The red input syncs on '
	code 'keyup'
	text 'events.'

input '.blue', ->
	text 'The blue input syncs on '
	code 'change'
	text 'events.'
