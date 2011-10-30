print = (err, data, warn) ->
	if err then console.error err
	if warn then console.warn warn
	text data

example = (module) ->
	div '.row', ->
		div '.span4.example', ->
			@load "./examples/#{module}/left.coffee"
		div '.span8', ->
			@pygmented "./examples/#{module}/code.coffee", print
			script type: 'text/coffeescript', ->
				@paste "./examples/#{module}/code.coffee", print
		div '.span4', ->
			@load "./examples/#{module}/right.coffee"
	div '.row', ->
		@markdown "./examples/#{module}/text.md", print

doctype 5
html ->
	head ->
		meta charset: 'utf-8'
		title "Myelin"
		link rel: 'stylesheet', href: 'lib/vendor/bootstrap.css'
		link rel: 'stylesheet', href: 'lib/vendor/pygments.css'
		style type: 'text/css', -> @stylus './main.sty'
	body ->
		comment 'TopBar'
		div '.topbar', data: {scrollspy: 'scrollspy'}, ->
			div '.fill', ->
				div '.container', ->
					h3 -> a href: '#', -> 'Myelin'
					ul ->
						li -> a href: '#intro', -> 'Introduction'
						li -> a href: '#basics', -> 'The Basics'
						li -> a href: '#behavior', -> 'Behavior'
						li -> a href: '#api', -> 'API'
						li -> a href: '#resources', -> 'Resources'
				comment 'Pretty color time!'
				div '#colors', ->
					div '.red', ->
					div '.amber', ->
					div '.green', ->
					div '.cyan', ->
					div '.blue', ->
					div '.magenta', ->

		comment "Masthead (can you tell I'm using bootstrap yet?)"
		header '.masthead#overview', ->
			div '.inner', ->
				div '.container', ->
					h1 ->
						text 'Myelin '
						small -> 'links Backbone.js models to document objects through Views using Handlers'

		comment 'These scripts must be loaded now if the example scripts are to work properly'
		script type: "text/javascript", src: "lib/vendor/coffee-script.js"
		script type: "text/javascript", src: "lib/vendor/jquery.js"
		script type: "text/javascript", src: "lib/vendor/underscore.js"
		script type: "text/javascript", src: "lib/vendor/backbone.js"
		script type: "text/coffeescript", src: "lib/myelin.coffee"

		div '.container', ->
			section '#intro', ->
				div '.page-header', ->
					h1 ->
						text 'Introduction '
						small -> 'a quick example to get you started'
				example 'intro'

			section '#basics', ->
				div '.page-header', ->
					h1 ->
						text 'The Basics '
						small -> "you'll be linking elements in no time!"
				# example 'trivial'
				# example 'keyup'
				# example 'reuse'
				# example 'delegate'
				# example 'changetype'
				# There should be more basic examples. Check your scratch.

		comment 'These scripts can be loaded as late as necessary'
		script type: "text/javascript", src: "lib/vendor/bootstrap-scrollspy.js"
