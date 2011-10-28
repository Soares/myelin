EXAMPLES = $(shell ls lib/examples)

# TODO: Don't rebuild if not necessary.
page:
	mkdir -p build/examples
	pygmentize -S default -f html > build/pygments.css
	stylus -u nib < lib/index.sty > build/index.css
	
	for NAME in $(EXAMPLES) ; do \
		pygmentize -f html -o lib/examples/$$NAME/code.html lib/examples/$$NAME/code.coffee ;\
		cp lib/example.jade lib/examples/$$NAME/tmp.jade ;\
		jade < lib/examples/$$NAME/tmp.jade --path lib/examples/$$NAME/tmp.jade > build/examples/$$NAME.html ;\
		rm lib/examples/$$NAME/code.html ;\
		rm lib/examples/$$NAME/tmp.jade ;\
	done
	
	# jade < lib/index.jade --path build/index.jade > index.html

clean:
	rm index.html -f
	rm build -rf

#for ex in $(EXAMPLES) ; do \
#	pygmentize -f html -o lib/examples/$${ex}code.html lib/examples/$${ex}code.coffee ;\
#	jade < lib/example.jade --path lib/examples/$${ex}example.jade > build/examples/$(subst /,.html,$${ex}) ;\
#	rm lib/examples/$${ex}/code.html ;\
