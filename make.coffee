
# Ensure that the build directory exists
# mkdir -p build/examples

# Ensure that the pygment css exists
# if build/pygments.css does not exist:
#   pygmentize -S default -f html > build/pygments.css

# Build index.sty as necessary
# If index.sty has changed
#   stylus -u nib < lib/index.sty > build/index.css

# Build the examples
# for example in (dirs in lib/examples)
#   pygmentize -f html -o lib/examples/#{dir}/code.html local/examples/intro/code.coffee
#   cp lib/examples/template.jade lib/examples/#{dir}
#
#   jade < lib/examples/#{dir}/template.jade --path lib/examples/#{dir}/template.jade > build/examples/#{dir}.html
#
#   rm lib/examples/#{dir}/code.html
#   rm lib/examples/#{dir}/template.jade

# Build the index
#   jade < lib/index.jade --path lib/index.jade > index.html
