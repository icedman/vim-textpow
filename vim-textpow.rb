# frozen_string_literal: true

require './highlight'

# $debug = true
$doc_buffers = {}
$props = {}

$scope_hl_map = [
  %w[type StorageClass],
  ['storage.type', 'Identifier'],
  %w[constant Constant],
  ['constant.numeric', 'Number'],
  ['constant.character', 'Character'],
  %w[primitive Boolean],
  %w[variable StorageClass],
  %w[keyword Define],
  %w[declaration Conditional],
  %w[control Conditional],
  %w[operator Operator],
  %w[directive PreProc],
  %w[preprocessor Boolean],
  %w[macro Boolean],
  %w[require Include],
  %w[import Include],
  %w[function Function],
  %w[struct Structure],
  %w[class Structure],
  %w[modifier Boolean],
  %w[namespace StorageClass],
  %w[scope StorageClass],
  ['name.type', 'StorageClass'],
  # [ "name.type", "Variable" ],
  %w[tag Tag],
  ['name.tag', 'StorageClass'],
  %w[attribute StorageClass],
  # [ "attribute", "Variable" ],
  %w[property StorageClass],
  # [ "property", "Variable" ],
  %w[heading markdownH1],
  %w[string String],
  ['string.other', 'Label'],
  %w[comment Comment]
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
    block.make_dirty if block.was_within_comment != within_comment

    if block.dirty
      Vim.command("call prop_clear(#{n})")
      highlight_line(doc, line_nr, line, syntax, processor)

      spans = []
      spans = processor.spans unless $debug

      spans = highlight_order_spans(spans, line.length)

      # special comment block handling
      if spans.length.zero? && within_comment
        spans = []
        t = LineProcessor::Tag.new
        t.tag = 'comment.begin'
        t.comment_begin = true
        t.start = 0
        t.end = line.length
        spans << t
      end

      block.was_within_comment = within_comment

      # TODO: .. dirty-up comment blocks

      block.spans = spans

      spans.each do |t|
        start = t.start + 1
        len = t.end - t.start

        hl = nil
        $scope_hl_map.each do |pair|
          hl = pair[1] if t.tag.include? pair[0]
        end

        next unless hl

        if $props[hl].nil?
          Vim.command("call prop_type_add('#{hl}', { 'highlight': '#{hl}', 'priority': 0 })")
          $props[hl] = true
        end

        Vim.command("call prop_add(#{n},#{start}, { 'length': #{len}, 'type': '#{hl}'})")
      end
    end
    line_nr += 1
  end
end

def get_doc(n)
  $doc_buffers[n] = Doc.new if $doc_buffers[n].nil?
  $doc_buffers[n]
end

def highlight_current_buffer
  buf = Vim::Buffer.current
  doc = get_doc(buf.number)

  if doc.syntax.nil?
    ext = '?'
    fnr = buf.name.split('.')
    ext = fnr.last if fnr.length.positive?
    doc.syntax = Textpow.syntax(ext)
    doc.syntax = false unless doc.syntax
  end

  return if doc.syntax == false

  processor = if $debug
                Textpow::DebugProcessor.new
              else
                LineProcessor.new
              end

  pos = Vim::Window.current.cursor
  h = Vim::Window.current.height
  lc = Vim::Buffer.current.length

  ls = pos[0] - h
  le = pos[0] + h

  ls = 1 if ls < 1
  le = lc if le > lc

  lines = []
  (ls..le).each do |nr|
    lines << buf[nr]
  end

  highlight_lines doc, lines, ls, doc.syntax, processor

  Vim.command('syn off')
end

def update_current_buffer
  buf = Vim::Buffer.current
  doc = get_doc(buf.number)
  pos = Vim::Window.current.cursor

  # TODO: account for new lines added.. and copy stack
  block = doc.block_at(pos[0] - 1)
  block.make_dirty

  highlight_current_buffer
end

Vim.command('au BufEnter * :ruby highlight_current_buffer')
Vim.command('au CursorMoved,CursorMovedI * :ruby highlight_current_buffer')
Vim.command('au TextChanged,TextChangedI * :ruby update_current_buffer')
