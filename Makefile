LIB = lib
BUILD = build
EXAMPLES = examples

LEX = $(LIB)/$(EXAMPLES)/
BEX = $(BUILD)/$(EXAMPLES)/

MODULES = $(addprefix $(BEX),$(shell ls $(LEX)))

all: $(BUILD)/pygments.css $(BUILD)/style.css index.html

build:
	mkdir -p $(BEX)

$(BUILD)/pygments.css: build
	pygmentize -S default -f html > $(BUILD)/pygments.css

$(BUILD)/style.css: build lib/style.sty
	stylus -u nib < lib/style.sty > $(BUILD)/style.css

index.html: $(MODULES) lib/index.jade
	cp $(LIB)/index.jade $(BUILD)/
	jade < $(BUILD)/index.jade --path $(BUILD)/index.jade > $@

$(BEX)%: $(LEX)%/left.jade $(LEX)%/right.jade $(LEX)%/code.coffee $(LEX)%/text.md
	cp -R $(LEX)$(@F) $@
	pygmentize -f html -o $@/code.html $@/code.coffee
	markdown < $@/text.md > $@/text.html
	cp $(LIB)/block.jade $@/tmp.jade
	jade < $@/tmp.jade --path $@/tmp.jade > $@.html

clean:
	rm index.html -f
	rm build -rf
