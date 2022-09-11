$LOAD_PATH.unshift "textpow/lib"
require "textpow"

$doc_id = 0xff
$block_id = 0xff

# line_nr here should be zero based

class LineProcessor
  class Tag
    attr_accessor :tag
    attr_accessor :start
    attr_accessor :end
    attr_accessor :comment_begin
    attr_accessor :comment_end
  end

  attr_accessor :spans

  def initialize
    @stack = []
    @spans = []
  end

  def open_tag(name, position)
    t = Tag.new
    t.tag = name
    t.start = position
    t.end = position + 1
    t.comment_begin = (not name.nil? and name.include? "comment.begin")
    t.comment_end = (not name.nil? and name.include? "comment.end")
    @stack << t
    @spans << t
  end

  def close_tag(name, position)
    if @stack.length() > 0
      last = @stack.last
      last.end = position
      @stack.pop
    end
  end

  def new_line(line)
    @stack = []
    @spans = []
  end

  def start_parsing(name)
  end

  def end_parsing(name)
  end
end

class Doc
  class Block
    attr_accessor :id
    attr_accessor :dirty
    attr_accessor :parser_state
    attr_accessor :spans

    attr_accessor :was_within_comment

    def initialize
      @id = $block_id
      @dirty = true

      $block_id += 1
    end

    def make_dirty
      @parser_state = nil
      @spans = nil
      @dirty = true
    end
  end

  attr_accessor :id
  attr_accessor :syntax
  attr_accessor :blocks

  def initialize
    @id = $doc_id
    @blocks = []

    $doc_id += 1
  end

  def block_at(line_nr)
    while line_nr >= @blocks.length()
      insert_block(@blocks.length())
    end

    return @blocks[line_nr]
  end

  def previous_block(line_nr)
    if line_nr == 0
      return nil
    end

    block_at(line_nr - 1)
  end

  def next_block(line_nr)
    if line_nr + 1 >= @blocks.length()
      return nil
    end

    block_at(line_nr + 1)
  end

  def insert_block(line_nr)
    block = Block.new
    @blocks.insert(line_nr, block)

    block
  end

  def is_block_within_comment(line_nr, limit = 100)
    for n in 0..limit
      prev = previous_block(line_nr - n)
      if not prev.nil?
        if not prev.spans.nil? and prev.spans.length > 0
          last = prev.spans.last
          return last.comment_begin
        end
      end
    end
    return false
  end

  def remove_block(line_nr)
    block = @blocks[line_nr]
    @blocks.delete_at(line_nr)
    block
  end

  def make_dirty
    @blocks.each do |b|
      b.make_dirty
    end
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
  return res
end

def unserialize_state(state)
  res = []
  state.each do |s|
    res << [s["syntax"], s["match"]]
  end
  return res
end

def highlight_line(doc, line_nr, line, syntax, processor)
  block = doc.block_at line_nr
  next_block = doc.next_block line_nr
  previous_block = doc.previous_block line_nr

  stack = nil
  if previous_block.nil? or previous_block.parser_state.nil?
    stack = [[syntax, nil]]
  else
    stack = unserialize_state(previous_block.parser_state)
  end

  l = "#{line}\n"
  top, match = syntax.parse_line_by_line(stack, l, processor)
  block.parser_state = serialize_state(stack)

  # save open comment and open string
  # invalidate next block on changed comment and string if necessary

  block.dirty = false
  block
end

def highlight_order_spans(spans, length)
  res = []

  # todo
  # supposedly text format is evaluated ehere

  for i in 0..length
    t = nil

    spans.each do |s|
      if s.start <= i and i <= s.end
        t = s
      end
    end

    if t.nil? or t.tag.nil?
      next
    end

    tt = LineProcessor::Tag.new
    tt.tag = t.tag
    tt.start = t.start
    tt.comment_begin = t.comment_begin
    tt.comment_end = t.comment_end
    tt.end = length

    if res.length() > 0
      if res.last.tag == tt.tag
        res.last.end = length
        tt = nil
      end
    end

    if not tt.nil?
      if res.length() > 0
        res.last.end = i
      end
      if res.length() == 0 and tt.comment_end
        tt.start = 0
      end
      res << tt
    end
  end

  res
end
