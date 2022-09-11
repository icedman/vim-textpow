# frozen_string_literal: true

$LOAD_PATH.unshift "textpow/lib"
require "textpow"

require "./highlight"

# path = "textpow/examples/sample.c"
path = "textpow/examples/sample.js"
# path = "vim-textpow.rb"
# path = "/home/iceman/Developer/Projects/text_edit_superstring/tests/config.json"

Textpow.load_extensions("/home/iceman/.editor/extensions")
syntax = Textpow.syntax_from_filename(path)
# syntax = Textpow.syntax("ruby")

# puts syntax.language

text = File.read(path)

processor = Textpow::DebugProcessor.new
syntax.parse(text, processor)

# processor = LineProcessor.new

# doc = Doc.new
# n = 0
# text.each_line do |line|
#   highlight_line(doc, n, line, syntax, processor)
#   spans = highlight_order_spans processor.spans, line.length()

#   puts line
#   spans.each do |s|
#     puts "#{s.tag} (#{s.start} #{s.end})"
#   end

#   puts "---"

#   n += 1
# end
