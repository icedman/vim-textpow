$LOAD_PATH.unshift 'lib'
require 'textpow'

syntax = Textpow.syntax('c')
text = File.read('examples/sample.c')
processor = Textpow::DebugProcessor.new

stack = [[syntax, nil]]
lines = []
states = []
text.each_line do |line|
    lines << line
    puts line
    syntax.parse_line_by_line(stack, line, processor)
    top, match = stack.last
    stack = [[syntax, nil], [top, match]]
    states << stack
end

puts "----"

stack = [[syntax, nil]]

lines[0] = "/*"
lines.each_with_index do |line, index|
    puts "#{index} #{line}"
    if index > 0
        stack = states[index - 1]
    end
    syntax.parse_line_by_line(stack, line, processor)
end

