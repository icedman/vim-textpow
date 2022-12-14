# frozen_string_literal: true

require_relative 'highlight'

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
  # ["string.other", "Label"],
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

    if block.dirty
      # Textpow.logger().debug("hl #{line_nr}")

      Vim.command("call prop_clear(#{n})")

      if line.length < 500
        highlight_line(doc, line_nr, line, syntax, processor)
      else
        processor.spans = []
      end

      spans = highlight_order_spans(processor.spans, line.length)

      # special comment block and string block handling
      within_comment = spans.length.zero? && doc.is_block_within_comment(line_nr)
      within_string = spans.length.zero? && doc.is_block_within_string(line_nr)

      # TODO: remove too specific hacks
      within_string = true if !within_string && spans.length == 1 && (spans[0].tag&.include? 'escape')

      if within_comment || within_string
        spans = []
        t = LineProcessor::Tag.new
        if within_comment
          t.tag = 'comment.begin'
          t.comment_begin = true
        else
          t.tag = 'string.begin'
          t.string_begin = true
        end
        t.start = 0
        t.end = line.length
        spans << t
      end

      # dirty-up next block if necessary
      next_block.make_dirty if !next_block.nil? && !next_block.dirty && !compare_highlight_spans(block.prev_spans,
                                                                                                 spans)

      block.prev_spans = spans
      block.spans = spans

      theme = Textpow.theme()

      spans.each do |t|
        start = t.start + 1
        len = t.end - t.start

        hl = nil

        if theme
          style = theme.style_for_scope(t.tag)
          if style
            fg = style.foreground[1..]
            hl = fg
            Vim.command("highlight #{hl} guifg=##{hl}")
          end
        else
          $scope_hl_map.each do |pair|
            hl = pair[1] if t.tag.include? pair[0]
          end
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

def highlight_current_buffer(make_dirty = false)
  buf = Vim::Buffer.current
  doc = get_doc(buf.number)

  doc.make_dirty if make_dirty

  if doc.syntax.nil?
    doc.syntax = Textpow.syntax_from_filename(buf.name)
    doc.syntax = false unless doc.syntax
  end

  return if doc.syntax == false

  processor = LineProcessor.new

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
  # Textpow.logger().debug('--- update ---')
  buf = Vim::Buffer.current
  doc = get_doc(buf.number)
  pos = Vim::Window.current.cursor

  block = doc.block_at(pos[0] - 1)
  block.make_dirty

  highlight_current_buffer
end

Vim.command('au BufEnter * :ruby highlight_current_buffer true')
Vim.command('au CursorMoved,CursorMovedI * :ruby highlight_current_buffer')
Vim.command('au TextChanged,TextChangedI * :ruby update_current_buffer')

Textpow.load_extensions(File.expand_path('~/.vim/plugged/vim-textpow/extensions'))
Textpow.load_extensions(File.expand_path('~/.vim/ruby/vim-textpow/extensions'))

# Textpow.logger().debug(Textpow::Extension.get_extensions)
# Textpow.logger().debug(Textpow::Extension.theme_from_name("Monokai"))

# Textpow.theme("Red")
# Textpow.theme("Monokai")
Textpow.theme('Dracula')
