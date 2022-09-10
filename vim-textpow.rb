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
    n = line_nr + 1

    if block.dirty
      Vim::command("call prop_clear(#{n})")
      highlight_line(doc, line_nr, line, syntax, processor)

      spans = []
      if not $debug
        spans = processor.spans
      end

      spans = highlight_order_spans(spans, line.length)

      spans.each do |t|

        start = t.start + 1
        len = t.end - t.start

        # if pos[0] == n and pos[1] >= t.start and pos[1] < t.end
        #   puts t.tag
        # end

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

def get_buffer(n)
  if $doc_buffers[n].nil?
    $doc_buffers[n] = Doc.new
  end
  return $doc_buffers[n]
end

def highlight_current_buffer()
  buf = Vim::Buffer.current()
  doc = get_buffer(buf.number)

  if doc.syntax.nil?
    # ext = "js.jquery"
    ext = "c"
    doc.syntax = Textpow.syntax(ext)
    if not doc.syntax
      doc.syntax = false
    end
  end

  if doc.syntax == false
    return
  end

  # doc.make_dirty

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
  doc = get_buffer(buf.number)
  pos = Vim::Window.current.cursor

  block = doc.block_at(pos[0] - 1)
  block.make_dirty

  highlight_current_buffer()
end

Vim::command("au BufEnter * :ruby highlight_current_buffer")
Vim::command("au CursorMoved,CursorMovedI * :ruby highlight_current_buffer")
Vim::command("au TextChanged,TextChangedI * :ruby update_current_buffer")
