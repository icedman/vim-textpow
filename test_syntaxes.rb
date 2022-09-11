$LOAD_PATH.unshift "textpow/lib"
require "textpow"

path = "vim-textpow.rb"


def dump(syntax)
    ss = syntax.syntices
    puts ss
end

Textpow.load_extensions("/home/iceman/.editor/extensions")
# syntax = Textpow.syntax_from_filename(path)
syntax = Textpow.syntax("ruby")


dump syntax