LIB = lib
BUILD = build
EXAMPLES = examples

LEX = $(LIB)/$(EXAMPLES)/
BEX = $(BUILD)/$(EXAMPLES)/

MODULES = $(addprefix $(BEX),$(shell ls $(LEX)))
MODTARGETS = $(addsuffix .html,$(MODULES))

all: $(BUILD)/pygments.css $(BUILD)/style.css index.html

build:
	mkdir -p $(BUILD)
	for mod in $(MODULES) ; do \
		mkdir -p $$mod ; \
	done

$(BUILD)/pygments.css: build
	pygmentize -S default -f html > $(BUILD)/pygments.css

$(BUILD)/style.css: build lib/style.sty
	stylus -u nib < lib/style.sty > $(BUILD)/style.css

index.html: $(MODTARGETS) lib/index.jade
	cp $(LIB)/index.jade $(BUILD)/
	jade < $(BUILD)/index.jade --path $(BUILD)/index.jade > $@

$(BEX)%.html: $(BEX)%/left.html $(BEX)%/right.html $(BEX)%/code.html $(BEX)%/code.coffee $(BEX)%/text.html
	cp $(LIB)/block.jade $(<D)
	jade < $(<D)/block.jade --path $(<D)/block.jade > $@

$(BEX)%/left.html: $(LEX)%/left.jade
	jade < $< --path $< > $@

$(BEX)%/right.html: $(LEX)%/right.jade
	jade < $< --path $< > $@

$(BEX)%/code.html: $(LEX)%/code.coffee
	pygmentize -f html -o $@ $<

$(BEX)%/code.coffee: $(LEX)%/code.coffee
	cp $< $@

$(BEX)%/text.html: $(LEX)%/text.md
	markdown < $< > $@

clean:
	rm index.html -f
	rm $(BUILD) -rf
