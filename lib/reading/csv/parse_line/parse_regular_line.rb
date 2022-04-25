require "active_support/core_ext/object/blank"
require_relative "../../errors"
require_relative "parse_line"
require_relative "../parse_attribute/parse_attributes"

module Reading
  module Csv
    class Parse
      # ParseRegularLine is a function that parses a normal row in a CSV reading
      # log into an array of item data (hashes).
      class ParseRegularLine < ParseLine
        private

        def after_initialize
          setup_parse_attributes
        end

        def before_parse(line)
          set_columns(line)
          ensure_name_column_present
        end

        def multi_items_to_be_split_by_format_emojis
          @columns[:name]
        end

        def setup_parse_attributes
          @parse_attributes ||= @config.fetch(:item).fetch(:template).map { |attribute, _default|
            parser_class_name = "Parse#{attribute.to_s.split("_").map(&:capitalize).join}"
            [attribute, self.class.const_get(parser_class_name).new(@config)]
          }.to_h
          .merge(custom_parse_attributes)
        end

        def custom_parse_attributes
          numeric = custom_parse_attributes_of_type(:numeric) { |value|
            Float(value, exception: false)
          }

          text = custom_parse_attributes_of_type(:text) { |value|
            value
          }

          (numeric + text).to_h
        end

        def custom_parse_attributes_of_type(type, &process_value)
          @config.fetch(:csv).fetch(:"custom_#{type}_columns").map { |attribute, _default_value|
            custom_class = Class.new ParseAttribute

            custom_class.define_method :call do |item_name, columns|
              value = columns[attribute.to_sym]&.strip&.presence
              process_value.call(value)
            end

            [attribute.to_sym, custom_class.new(@config)]
          }
        end

        def set_columns(line)
          @columns = @config
            .fetch(:csv).fetch(:columns)
            .select { |_name, enabled| enabled }
            .keys
            .concat(@config.fetch(:csv).fetch(:custom_numeric_columns).keys)
            .concat(@config.fetch(:csv).fetch(:custom_text_columns).keys)
            .zip(line.split(@config.fetch(:csv).fetch(:column_separator)))
            .to_h
        end

        def ensure_name_column_present
          if @columns[:name].nil? || @columns[:name].strip.empty?
            raise InvalidItemError, "The Name column must not be blank"
          end
        end

        def item_data(name)
          @config
            .fetch(:item).fetch(:template)
            .merge(@config.fetch(:csv).fetch(:custom_numeric_columns))
            .merge(@config.fetch(:csv).fetch(:custom_text_columns))
            .map { |attribute, default_value|
              parsed = @parse_attributes.fetch(attribute).call(name, @columns)

              [attribute, parsed || default_value]
            }.to_h
        end
      end
    end
  end
end
