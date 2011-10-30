LIB = lib
BUILD = build
LIBEX = $(LIB)/examples
BUILDEX = $(BUILD)/examples
EXAMPLES = $(addsuffix .html,$(addprefix $(BUILDEX)/,$(shell ls $(LIBEX))))

all: $(BUILD)/main.css index.html

index.html: $(BUILD)/index.jade $(EXAMPLES)
	jade < $< --path $< > $@

$(BUILD)/index.jade: $(LIB)/index.jade
	mkdir -p $(@D)
	cp $< $@

$(BUILD)/main.css: $(LIB)/main.sty
	mkdir -p $(@D)
	stylus -u nib < $< > $@

$(BUILDEX)/%.html: $(BUILDEX)/%/example.jade $(BUILDEX)/%/left.html $(BUILDEX)/%/right.html $(BUILDEX)/%/code.html $(BUILDEX)/%/text.html
	jade < $< --path $< > $@

$(BUILDEX)/%/example.jade: $(LIB)/example.jade
	mkdir -p $(@D)
	cp $< $@

$(BUILDEX)/%/left.html: $(LIBEX)/%/left.jade
	jade < $< --path $< > $@

$(BUILDEX)/%/right.html: $(LIBEX)/%/right.jade
	jade < $< --path $< > $@

$(BUILDEX)/%/code.html: $(LIBEX)/%/code.coffee
	pygmentize -f html -o $@ $<

$(BUILDEX)/%/code.coffee: $(LIBEX)/%/code.coffee
	mkdir -p $(@D)
	cp $< $@

$(BUILDEX)/%/text.html: $(LIBEX)/%/text.md
	markdown < $< > $@

clean:
	rm index.html -f
	rm $(BUILD) -rf
