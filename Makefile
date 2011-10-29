EXAMPLES = $(shell ls lib/examples)

# TODO: Don't rebuild if not necessary.
page:
	mkdir -p build/examples
	pygmentize -S default -f html > build/pygments.css
	stylus -u nib < lib/style.sty > build/style.css
	
	for NAME in $(EXAMPLES) ; do \
		pygmentize -f html -o lib/examples/$$NAME/code.html lib/examples/$$NAME/code.coffee ;\
		cp lib/block.jade lib/examples/$$NAME/tmp.jade ;\
		jade < lib/examples/$$NAME/tmp.jade --path lib/examples/$$NAME/tmp.jade > build/examples/$$NAME.html ;\
		rm lib/examples/$$NAME/code.html ;\
		rm lib/examples/$$NAME/tmp.jade ;\
	done
	
	cp lib/index.jade build/
	jade < build/index.jade --path build/index.jade > index.html

clean:
	rm index.html -f
	rm build -rf

# markdown < lib/examples/$$NAME/text.md > lib/examples/$NAME/text.html
# ...
# rm lib/examples/$$NAME/text.html
