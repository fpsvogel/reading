# frozen_string_literal: true

require_relative "../util"
require_relative "../errors"

module Reading
  module Csv
    class Parse
      # ParseLine is a base class that holds common behaviors.
      class ParseLine
        attr_private :line, :config, :default

        def initialize(merged_config)
          @line = nil
          @config ||= merged_config
          setup_default
          after_initialize
        end

        def setup_default
          @default =
            config.fetch(:item).fetch(:template)
                  .map do |attribute, value|
                    if value.is_a?(Array) && value.first.is_a?(Hash)
                      [attribute, []]
                    else
                      [attribute, value]
                    end
                  end.to_h
        end

        def call(line, &postprocess)
          @line = line
          before_parse
          titles = []
          items = split_by_format_emojis.map do |name|
            data = item_data(name)
            if titles.include?(name)
              raise InvalidItemError, "A title must not appear more than once in the list"
            end
            titles << data[:title]
            if block_given?
              postprocess.call(data)
            else
              data
            end
          end.compact
          items
        rescue InvalidItemError, StandardError => e
          # TODO instead of rescuing StandardError here, test missing
          # initial/middle columns in ParseRegularLine#set_columns, and raise
          # appropriate errors if possible.
          unless e.is_a? InvalidItemError
            if config.fetch(:errors).fetch(:catch_all_errors)
              e = InvalidItemError.new("A line could not be parsed. Check this line")
            else
              raise e
            end
          end
          e.handle(source: line, config: config)
          []
        ensure
          # reset to pre-call state.
          initialize(config)
        end

        private

        def split_by_format_emojis
          multi_items_to_be_split_by_format_emojis
            .split(config.fetch(:csv).fetch(:regex).fetch(:formats_split))
            .tap do |names|
              names.first.sub!(config.fetch(:csv).fetch(:regex).fetch(:dnf), "")
              names.first.sub!(config.fetch(:csv).fetch(:regex).fetch(:progress), "")
            end
            .map { |name| name.strip.sub(/\s*[,;]\z/, "") }
            .partition { |name| name.match?(/\A#{config.fetch(:csv).fetch(:regex).fetch(:formats)}/) }
            .reject(&:empty?)
            .first
        end

        def after_initialize
        end

        def before_parse
        end

        def multi_items_to_be_split_by_format_emojis
          raise NotImplementedError, "#{self.class} should have implemented #{__method__}"
        end

        def item_data(name)
          raise NotImplementedError, "#{self.class} should have implemented #{__method__}"
        end
      end
    end
  end
end
