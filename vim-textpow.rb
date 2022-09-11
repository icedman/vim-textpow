require "./highlight.rb"

# $debug = true
$doc_buffers = {}
$props = {}

$scope_hl_map = [
  ["type", "StorageClass"],
  ["storage.type", "Identifier"],
  ["constant", "Constant"],
  ["constant.numeric", "Number"],
  ["constant.character", "Character"],
  ["primitive", "Boolean"],
  ["variable", "StorageClass"],
  ["keyword", "Define"],
  ["declaration", "Conditional"],
  ["control", "Conditional"],
  ["operator", "Operator"],
  ["directive", "PreProc"],
  ["preprocessor", "Boolean"],
  ["macro", "Boolean"],
  ["require", "Include"],
  ["import", "Include"],
  ["function", "Function"],
  ["struct", "Structure"],
  ["class", "Structure"],
  ["modifier", "Boolean"],
  ["namespace", "StorageClass"],
  ["scope", "StorageClass"],
  ["name.type", "StorageClass"],
  # [ "name.type", "Variable" ],
  ["tag", "Tag"],
  ["name.tag", "StorageClass"],
  ["attribute", "StorageClass"],
  # [ "attribute", "Variable" ],
  ["property", "StorageClass"],
  # [ "property", "Variable" ],
  ["heading", "markdownH1"],
  ["string", "String"],
  ["string.other", "Label"],
  ["comment", "Comment"],
]

# line_nr should be zero based
def highlight_lines(doc, lines, ls, syntax, processor)
  line_nr = ls - 1
  priority = 0
  lines.each do |line|
    block = doc.block_at line_nr
    previous_block = doc.previous_block line_nr
    next_block = doc.next_block line_nr

    n = line_nr + 1

    within_comment = doc.is_block_within_comment(line_nr)
    if block.was_within_comment != within_comment
      block.make_dirty
    end

    if block.dirty
      Vim::command("call prop_clear(#{n})")
      highlight_line(doc, line_nr, line, syntax, processor)

      spans = []
      if not $debug
        spans = processor.spans
      end

      spans = highlight_order_spans(spans, line.length)

      # special comment block handling
      if spans.length == 0 and within_comment
        spans = []
        t = LineProcessor::Tag.new
        t.tag = "comment.begin"
        t.comment_begin = true
        t.start = 0
        t.end = line.length
        spans << t
      end

      block.was_within_comment = within_comment

      # todo .. dirty-up comment blocks

      block.spans = spans

      spans.each do |t|
        start = t.start + 1
        len = t.end - t.start

        hl = nil
        $scope_hl_map.each do |pair|
          if t.tag.include? pair[0]
            hl = pair[1]
          end
        end

        if hl
          if $props[hl].nil?
            Vim::command("call prop_type_add('#{hl}', { 'highlight': '#{hl}', 'priority': 0 })")
            $props[hl] = true
          end

          Vim::command("call prop_add(#{n},#{start}, { 'length': #{len}, 'type': '#{hl}'})")
        end
      end
    end
    line_nr += 1
  end
end

def get_doc(n)
  if $doc_buffers[n].nil?
    $doc_buffers[n] = Doc.new
  end
  return $doc_buffers[n]
end

def highlight_current_buffer()
  buf = Vim::Buffer.current()
  doc = get_doc(buf.number)

  if doc.syntax.nil?
    ext = "?"
    fnr = buf.name.split(".")
    if fnr.length > 0
      ext = fnr.last
    end
    doc.syntax = Textpow.syntax(ext)
    if not doc.syntax
      doc.syntax = false
    end
  end

  if doc.syntax == false
    return
  end

  if $debug
    processor = Textpow::DebugProcessor.new
  else
    processor = LineProcessor.new
  end

  pos = Vim::Window.current.cursor
  h = Vim::Window.current.height
  lc = Vim::Buffer.current.length

  ls = pos[0] - h
  le = pos[0] + h

  if ls < 1
    ls = 1
  end
  if le > lc
    le = lc
  end

  lines = []
  for nr in ls..le
    lines << buf[nr]
  end

  highlight_lines doc, lines, ls, doc.syntax, processor

  Vim::command("syn off")
end

def update_current_buffer()
  buf = Vim::Buffer.current()
  doc = get_doc(buf.number)
  pos = Vim::Window.current.cursor

  # todo account for new lines added.. and copy stack
  block = doc.block_at(pos[0] - 1)
  block.make_dirty

  highlight_current_buffer()
end

Vim::command("au BufEnter * :ruby highlight_current_buffer")
Vim::command("au CursorMoved,CursorMovedI * :ruby highlight_current_buffer")
Vim::command("au TextChanged,TextChangedI * :ruby update_current_buffer")
