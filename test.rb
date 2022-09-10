require './vim-textmate.rb'

# $debug = true
$doc_buffers = {}
$props = {}

$scope_hl_map = [
  [ "type", "StorageClass" ],
  [ "storage.type", "Identifier" ],
  [ "constant", "Constant" ],
  [ "constant.numeric", "Number" ],
  [ "constant.character", "Character" ],
  [ "primitive", "Boolean" ],
  [ "variable", "StorageClass" ],
  [ "keyword", "Define" ],
  [ "declaration", "Conditional" ],
  [ "control", "Conditional" ],
  [ "operator", "Operator" ],
  [ "directive", "PreProc" ],
  [ "preprocessor", "Boolean" ],
  [ "macro", "Boolean" ],
  [ "require", "Include" ],
  [ "import", "Include" ],
  [ "function", "Function" ],
  [ "struct", "Structure" ],
  [ "class", "Structure" ],
  [ "modifier", "Boolean" ],
  [ "namespace", "StorageClass" ],
  [ "scope", "StorageClass" ],
  [ "name.type", "StorageClass" ],
  # [ "name.type", "Variable" ],
  [ "tag", "Tag" ],
  [ "name.tag", "StorageClass" ],
  [ "attribute", "StorageClass" ],
  # [ "attribute", "Variable" ],
  [ "property", "StorageClass" ],
  # [ "property", "Variable" ],
  [ "heading", "markdownH1" ],
  [ "string", "String" ],
  [ "string.other", "Label" ],
  [ "comment", "Comment"],
]

def order_spans(spans, length)
  spans
end

def highlight_lines(doc, lines, syntax, processor)
  pos = Vim::Window.current.cursor
  line_nr = 0
  priority = 0
  lines.each do |line|
      block = doc.block_at line_nr
      block.make_dirty
      if block.dirty

        n = line_nr + 1
        Vim::command("call prop_clear(#{n})")
        highlight_line(doc, n, line, syntax, processor)

        spans = []
        if not $debug
          spans = processor.spans
        end

        spans = order_spans(spans, line.length())

        spans.each do |t|
          start = t.start + 1
          len = t.end - t.start

          if pos[0] == n and pos[1] >= t.start and pos[1] < t.end
            puts t.tag
          end

          # hl = 'Constant'
          hl = nil
          $scope_hl_map.each do |pair|
            if t.tag.include? pair[0]
              hl = pair[1]
            end
          end

          # puts "#{t.tag} => #{hl}"

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

$syntax = Textpow.syntax("c")

def parse_current_buffer()
  buf = Vim::Buffer.current()
  doc = get_buffer(buf.number)
  doc.make_dirty

  if $debug
    processor = Textpow::DebugProcessor.new
  else
    processor = LineProcessor.new
  end

  lines = []
  for nr in 1 .. buf.length() do
    lines << buf[nr]
  end
  
  highlight_lines doc, lines, $syntax, processor
  # Vim::command("syn off")
end

Vim::command("au BufEnter * :ruby parse_current_buffer")
# Vim::command("au CursorMoved,CursorMovedI * :ruby parse_current_buffer")
# Vim::command("au TextChanged,TextChangedI * :ruby parse_current_buffer")
