require "./highlight.rb"

syntax = Textpow.syntax("c")
text = File.read("textpow/examples/sample.c")
# processor = LineProcessor.new

processor = Textpow::DebugProcessor.new
syntax.parse(text, processor)

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
