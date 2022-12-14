# frozen_string_literal: true

require_relative "textpow/lib/textpow"

$doc_id = 0xff
$block_id = 0xff

# line_nr here should be zero based

class LineProcessor
  class Tag
    attr_accessor :tag, :start, :end, :comment_begin, :comment_end, :string_begin, :string_end
  end

  attr_accessor :spans

  def initialize
    @stack = []
    @spans = []
    @comment_begin = false
    @comment_end = false
    @string_begin = false
    @string_end = false
  end

  def open_tag(name, position)
    t = Tag.new
    t.tag = name
    t.start = position
    t.end = position
    t.comment_begin = (!name.nil? and name.include? "comment.begin")
    t.comment_end = (!name.nil? and name.include? "comment.end")
    t.string_begin = (!name.nil? and name.include? "string.begin")
    t.string_end = (!name.nil? and name.include? "string.end")

    if @stack.length.positive? && !t.comment_begin && name && name.include?("comment") && (@stack.last.tag.include? "comment.block")
      t.comment_begin = true
    end

    @stack << t
    @spans << t
  end

  def close_tag(name, position)
    if @stack.length.positive?
      last = @stack.last
      last.end = position
      @stack.pop
    end

    if @stack.length.positive? && name && name.include?("comment.block") && (@stack.last.tag.include? "comment")
      @stack.last.comment_end = true
    end
  end

  def new_line(_line)
    @stack = []
    @spans = []
  end

  def start_parsing(name); end

  def end_parsing(name); end
end

##
# Doc contains parsers and spans states of a buffer. It tries to mirrow
# the buffer line for line as a Block

class Doc
  class Block
    attr_accessor :id, :dirty, :parser_state, :spans, :prev_spans

    def initialize
      @id = $block_id
      @dirty = true

      $block_id += 1
    end

    def make_dirty
      @parser_state = nil
      @dirty = true
    end
  end

  attr_accessor :id, :syntax, :blocks

  def initialize
    @id = $doc_id
    @blocks = []

    $doc_id += 1
  end

  def block_at(line_nr)
    insert_block(@blocks.length) while line_nr >= @blocks.length

    @blocks[line_nr]
  end

  def previous_block(line_nr)
    return nil if line_nr.zero?

    block_at(line_nr - 1)
  end

  def next_block(line_nr)
    return nil if line_nr + 1 >= @blocks.length

    block_at(line_nr + 1)
  end

  def insert_block(line_nr)
    block = Block.new
    @blocks.insert(line_nr, block)

    block
  end

  def is_block_within_comment(line_nr, limit = 100)
    (0..limit).each do |n|
      prev = previous_block(line_nr - n)
      if !prev.nil? && (!prev.spans.nil? && prev.spans.length.positive?)
        last = prev.spans.last
        return last.comment_begin
      end
    end
    false
  end

  def is_block_within_string(line_nr, limit = 100)
    (0..limit).each do |n|
      prev = previous_block(line_nr - n)
      if !prev.nil? && (!prev.spans.nil? && prev.spans.length.positive?)
        last = prev.spans.last
        return last.string_begin
      end
    end
    false
  end

  def remove_block(line_nr)
    block = @blocks[line_nr]
    @blocks.delete_at(line_nr)
    block
  end

  def make_dirty
    @blocks.each(&:make_dirty)
  end

  def print
    @blocks.each do |b|
      puts b
    end
  end
end

def serialize_state(stack)
  res = []
  stack.each do |s|
    obj = {}
    obj["syntax"] = s[0]
    obj["match"] = s[1]
    res << obj
  end
  res
end

def unserialize_state(state)
  res = []
  state.each do |s|
    res << [s["syntax"], s["match"]]
  end
  res
end

def compare_highlight_spans(prev, current)
  return false unless prev
  return false if prev.length != current.length
  return false if (prev.length.positive? && current.length.positive?) && prev.last.tag != current.last.tag

  true
end

def highlight_line(doc, line_nr, line, syntax, processor)
  block = doc.block_at line_nr
  next_block = doc.next_block line_nr
  previous_block = doc.previous_block line_nr

  stack = nil
  stack = if previous_block.nil? || previous_block.parser_state.nil?
      [[syntax, nil]]
    else
      unserialize_state(previous_block.parser_state)
    end

  l = "#{line}\n"
  error = syntax.parse_line_by_line(stack, l, processor)
  block.parser_state = serialize_state(stack) unless error

  block.dirty = false
  block
end

def highlight_order_spans(spans, length)
  res = []

  # todo
  # supposedly text format is evaluated ehere

  (0..length).each do |i|
    t = nil

    spans.each do |s|
      t = s if (s.start <= i) && (i < s.end)
    end

    next if t.nil? || t.tag.nil?

    tt = LineProcessor::Tag.new
    tt.tag = t.tag
    tt.start = t.start
    tt.comment_begin = t.comment_begin
    tt.comment_end = t.comment_end
    tt.string_begin = t.string_begin
    tt.string_end = t.string_end
    tt.end = length

    if res.length.positive? && (res.last.tag == tt.tag)
      res.last.end = length
      tt = nil
    end

    next if tt.nil?

    res.last.end = i if res.length.positive?
    tt.start = 0 if res.length.zero? && (tt.comment_end || tt.string_end)
    res << tt
  end

  res
end
