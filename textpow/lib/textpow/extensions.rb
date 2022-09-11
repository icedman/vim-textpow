# frozen_string_literal: true

require 'json'

module Textpow
  class Extension
    attr_accessor :path, :grammars, :themes

    class Grammar
      attr_accessor :language, :path, :scopeName, :extensions, :filenames
    end

    @@extensions = []

    def get_extensions()
      @@extensions
    end

    def load_package(path)
      dirpath = File.dirname(path)
      table = JSON.load_file(path)
      contributes = table['contributes']
      ext = Extension.new
      ext.path = path
      if contributes
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
      end

      @@extensions << ext if ext.grammars
    end

    def load_extensions(path)
      files = Dir["#{path}/*"]

      files.each do |f|
        load_package("#{f}/package.json")
      end
    end

    def grammar_from_filepath(path)
      if !path
        return nil
      end
      
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
