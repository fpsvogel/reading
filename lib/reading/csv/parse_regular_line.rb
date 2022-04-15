require "active_support/core_ext/object/blank"
require "attr_extras"
require_relative "../errors"
require_relative "parse_line"
require_relative "parse_attributes"

module Reading
  module Csv
    class Parse
      # ParseRegularLine is a function that parses a normal row in a CSV reading
      # log into an array of item data (hashes).
      class ParseRegularLine < ParseLine
        attr_private :columns, :parse_attributes

        private

        def after_initialize
          setup_parse_attributes
          setup_custom_parse_attributes
        end

        def before_parse
          set_columns
          ensure_name_column_present
        end

        def multi_items_to_be_split_by_format_emojis
          columns[:name]
        end

        def setup_parse_attributes
          @parse_attributes ||= config.fetch(:item).fetch(:template).map { |attribute, _default|
            parser_class_name = "Parse#{attribute.to_s.split("_").map(&:capitalize).join}"
            [attribute, self.class.const_get(parser_class_name).new(config)]
          }.to_h
        end

        def setup_custom_parse_attributes
          config.fetch(:csv).fetch(:custom_columns).each do |attribute, type|
            class_name = "Parse#{attribute.to_s.downcase.split("_").map(&:capitalize).join}"
            # The class for the custom attribute may already have been defined.
            next if parse_attributes.has_key?(attribute.to_sym)

            custom_class = Class.new ParseAttribute do
              @name = attribute
              @type = type

              def self.name
                @name
              end

              def self.type
                @type
              end

              def call(item_name, columns)
                value = columns[self.class.name.to_sym]&.strip&.presence
                if self.class.type == :number
                  Float(value, exception: false)
                else
                  value
                end
              end
            end

            self.class.const_set(class_name, custom_class)
            parse_attributes[attribute.to_sym] = custom_class.new(config)
          end
        end

        def set_columns
          @columns = config
            .fetch(:csv).fetch(:columns)
            .select { |_name, enabled| enabled }
            .keys
            .concat(config.fetch(:csv).fetch(:custom_columns).keys)
            .zip(line.split(config.fetch(:csv).fetch(:column_separator)))
            .to_h
        end

        def ensure_name_column_present
          if columns[:name].nil? || columns[:name].strip.empty?
            raise InvalidItemError, "The Name column must not be blank"
          end
        end

        def item_data(name)
          config
            .fetch(:item).fetch(:template)
            .merge(config.fetch(:csv).fetch(:custom_columns).keys.map { |k| [k, nil] }.to_h)
            .map { |attribute, _template_default|
              parsed = parse_attributes.fetch(attribute).call(name, columns)
              [attribute, parsed || default[attribute]]
            }.to_h
        end
      end
    end
  end
end
