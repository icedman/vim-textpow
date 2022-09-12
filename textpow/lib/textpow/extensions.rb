# frozen_string_literal: true

require 'json'

module Textpow
  class Extension
    attr_accessor :path, :grammars, :themes, :name, :displayName, :description, :version, :publisher

    class Grammar
      attr_accessor :language, :path, :scopeName, :extensions, :filenames
    end

    class Theme
      attr_accessor :name, :path, :label, :uiTheme
    end

    @@extensions = []

    def self.get_extensions
      @@extensions
    end

    def self.load_package(path)
      dirpath = File.dirname(path)
      table = JSON.load_file(path)
      contributes = table['contributes']
      ext = Extension.new
      ext.path = path

      ext.name = table['name']
      ext.displayName = table['displayName']
      ext.description = table['description']
      ext.version = table['version']
      ext.publisher = table['publisher']
      # Textpow.logger().debug(table)

      if contributes

        # find grammars
        ext.grammars = []
        grammars = contributes['grammars']
        grammars&.each do |g|
          gm = Grammar.new
          gm.language = g['language']
          gm.path = "#{dirpath}/#{g['path']}"
          gm.scopeName = g['scopeName']
          gm.extensions = []
          gm.filenames = []
          ext.grammars << gm
        end
        languages = contributes['languages']
        languages&.each do |lang|
          gm = nil
          ext.grammars.each do |exgm|
            if lang['id'] == exgm.language
              gm = exgm
              break
            end
          end

          if gm && lang['filenames']
            lang['filenames'].each do |e|
              gm.filenames << e
            end
          end

          if gm && lang['extensions']
            lang['extensions'].each do |e|
              gm.extensions << e
            end
          end
        end

        # themes
        ext.themes = []
        themes = contributes['themes']
        themes&.each do |t|
          thm = Theme.new
          thm.name = t['id']
          thm.name = t['label'] unless thm.name
          thm.label = t['label']
          thm.path = "#{dirpath}/#{t['path']}"
          thm.uiTheme = t['uiTheme']
          Textpow.logger.debug(t)
          ext.themes << thm
        end
      end

      @@extensions << ext if ext.grammars
    end

    def self.load_extensions(path)
      files = Dir["#{path}/*"]

      files.each do |f|
        load_package("#{f}/package.json")
      end
    end

    def self.theme_from_name(name)
      @@extensions.each do |ext|
        next unless ext.themes

        ext.themes.each do |t|
          thm = t
          return thm if thm.name && thm.name.downcase == name
        end
      end

      nil
    end

    def self.grammar_from_filepath(path)
      return nil unless path

      filename = File.basename(path)
      extension = File.extname(path)

      @@extensions.each do |ext|
        next unless ext.grammars

        ext.grammars.each do |gm|
          gm.filenames.each do |e|
            return gm if e == filename
          end
          gm.extensions.each do |e|
            return gm if e == extension
          end
        end
      end

      nil
    end
  end
end
