LIB = lib
BUILD = build
LIBEX = $(LIB)/examples
BUILDEX = $(BUILD)/examples
EXAMPLES = $(addsuffix .html,$(addprefix $(BUILDEX)/,$(shell ls $(LIBEX) | grep -v '.jade')))

all: $(BUILD)/main.css $(BUILD)/pygments.css index.html

index.html: $(BUILD)/index.jade $(EXAMPLES)
	jade < $< --path $< > $@

$(BUILD)/index.jade: $(LIB)/index.jade
	mkdir -p $(@D)
	cp $< $@

$(BUILD)/main.css: $(LIB)/main.sty
	mkdir -p $(@D)
	stylus -u nib < $< > $@

$(BUILD)/pygments.css:
	pygmentize -S default -f html > $@

$(BUILDEX)/%.html: $(BUILDEX)/%/template.jade $(BUILDEX)/%/left.html $(BUILDEX)/%/right.html $(BUILDEX)/%/code.html $(BUILDEX)/%/code.coffee $(BUILDEX)/%/text.html
	jade < $< --path $< > $@

$(BUILDEX)/%/template.jade: $(LIBEX)/template.jade
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
