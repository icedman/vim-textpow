# frozen_string_literal: true

require 'yaml'
require 'logger'

require_relative 'textpow/syntax'
require_relative 'textpow/debug_processor'
require_relative 'textpow/recording_processor'
require_relative 'textpow/score_manager'
require_relative 'textpow/extensions'
require_relative 'textpow/theme'
require_relative 'textpow/version'

module Textpow
  class ParsingError < StandardError; end

  def self.syntax_path
    File.join(File.dirname(__FILE__), 'textpow', 'syntax')
  end

  @@logger = nil

  def self.logger
    @@logger ||= Logger.new '/tmp/textpow.log'
    @@logger
  end

  @@syntax = {}
  def self.syntax(syntax_name)
    key = syntax_name.downcase
    if @@syntax.key?(key)
    else
      @@syntax[key] = uncached_syntax(syntax_name)
      @@syntax[key].language = key if @@syntax[key]
    end
    @@syntax[key]
  end

  @@themes = {}
  @@current_theme = nil

  def self.theme(theme_name = nil)
    return @@current_theme unless theme_name

    key = theme_name.downcase
    if @@themes.key?(key)
      @@current_theme = @@themes[key]
      @@themes[key]
    else
      thm = Extension.theme_from_name(key)
      if thm
        @@themes[key] = Textpow::Theme.load(thm.path)
        @@current_theme = @@themes[key]

        @@themes[key]
      end
    end
  end

  def self.syntax_from_filename(filename)
    gm = Extension.grammar_from_filepath(filename)
    if gm
      key = gm.language

      # priorities .syntax files
      # syntax_name = "source.#{key}"
      # path = File.join(syntax_path, "#{syntax_name}.syntax")
      # if File.exist?(path)
      #   @@syntax[syntax_name] = uncached_syntax(path)
      #   if @@syntax[key]
      #     @@syntax[syntax_name].language = key
      #     $logger.debug(path)
      #     return @@syntax[key]
      #   end
      # end

      if @@syntax.key?(key)
      else
        @@syntax[key] = SyntaxNode.load(gm.path)
        @@syntax[key].language = key if @@syntax[key]
      end
      @@syntax[key]
    end
  end

  def self.load_extensions(path)
    Extension.load_extensions(path)
  end

  def self.uncached_syntax(name)
    path = (find_syntax_by_path(name) ||
            find_syntax_by_scope_name(name.downcase) ||
            find_syntax_by_fuzzy_name(name.downcase))
    SyntaxNode.load(path) if path
  end

  def self.find_syntax_by_scope_name(name)
    path = File.join(syntax_path, "#{name}.syntax")
    path if File.exist?(path)
  end

  def self.find_syntax_by_fuzzy_name(name)
    path = Dir.glob(File.join(syntax_path, "*.#{name}.*")).min_by(&:size)
    path if path && File.exist?(path)
  end

  def self.find_syntax_by_path(path)
    path if File.file?(path)
  end
end
