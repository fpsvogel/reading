# frozen_string_literal: true

require_relative "../util"
require_relative "../errors"

module Reading
  module Csv
    class Parse
      # ParseLine is a base class that holds common behaviors.
      class ParseLine
        attr_private :line, :config

        def initialize(merged_config)
          @line = nil
          @config ||= merged_config
          after_initialize
        end

        def call(line, &postprocess)
          @line = line
          before_parse
          items = split_by_format_emojis.map.with_index do |name|
            data = item_data(name)
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
            if config.fetch(:error).fetch(:catch_all_errors)
              e = InvalidItemError.new("A line could not be parsed. Check this line")
            else
              raise e
            end
          end
          e.handle(source: line, &config.fetch(:error).fetch(:handle_error))
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
            .map { |name| name.strip.sub(/[,;]\z/, "") }
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
