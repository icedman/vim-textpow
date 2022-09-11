# frozen_string_literal: true

$LOAD_PATH.unshift "textpow/lib"
require "textpow"

require "./highlight"

# path = "textpow/examples/sample.c"
path = "textpow/examples/sample.js"

Textpow.load_extensions("/home/iceman/.editor/extensions")
syntax = Textpow.syntax_from_filename(path)

text = File.read(path)
processor = LineProcessor.new

# processor = Textpow::DebugProcessor.new
syntax.parse(text, processor)

doc = Doc.new
n = 0
text.each_line do |line|
  highlight_line(doc, n, line, syntax, processor)
  spans = highlight_order_spans processor.spans, line.length()

  puts line
  spans.each do |s|
    puts "#{s.tag} (#{s.start} #{s.end})"
  end

  puts "---"

  n += 1
end
