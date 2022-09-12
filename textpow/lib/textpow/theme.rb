# frozen_string_literal: true

require 'json'

module Textpow
  class Theme
    attr_accessor :tokenColors

    class ScopeFormat
      attr_accessor :name, :foreground
    end

    def self.load(file)
      table = JSON.load_file(file)
      Theme.new(table)
    end

    def initialize(table)
      @tokenColors = []

      table['tokenColors']&.each do |tc|
        scope = tc['scope']
        scope = [scope] unless scope.is_a? Array

        settings = tc['settings']
        if settings
          fg = settings['foreground']
          if fg
            scope&.each do |s|
              sf = ScopeFormat.new
              sf.name = s
              sf.foreground = fg
              @tokenColors << sf if sf.name
            end
          end
        end
      end
    end

    def style_for_scope(name)
      style = nil
      @tokenColors.each do |sf|
        if name.include? sf.name || !style
          style = sf
          # Textpow.logger().debug(">>#{sf.name}")
        end
      end

      style
    end
  end
end
