require_relative "../errors"
require_relative "../util/blank"
require_relative "../util/deep_fetch"
require_relative "row"
require_relative "../attribute/all_attributes"

module Reading
  # Parses a normal CSV row into an array of hashes of item data. Typically
  # a normal row describes one item and so it's parsed into an array containing
  # a single hash, but it's also possible for a row to describe multiple items.
  class RegularRow < Row
    using Util::DeepFetch

    private

    def after_initialize
      set_attribute_parsers
    end

    def before_parse
      set_columns
      ensure_head_column_present
    end

    def string_to_be_split_by_format_emojis
      @columns[:head]
    end

    def set_attribute_parsers
      @attribute_parsers ||= config.deep_fetch(:item, :template).map { |attribute_name, _default|
        attribute_name_camelcase = attribute_name.to_s.split("_").map(&:capitalize).join
        attribute_class_name = "#{attribute_name_camelcase}Attribute"
        attribute_class = self.class.const_get(attribute_class_name)

        [attribute_name, attribute_class.new(config)]
      }.to_h
      .merge(custom_attribute_parsers)
    end

    def custom_attribute_parsers
      numeric = custom_attribute_parsers_of_type(:numeric) do |value|
        Float(value, exception: false)
      end

      text = custom_attribute_parsers_of_type(:text) do |value|
        value
      end

      (numeric + text).to_h
    end

    def custom_attribute_parsers_of_type(type, &process_value)
      config.deep_fetch(:csv, :"custom_#{type}_columns").map { |attribute, _default_value|
        custom_class = Class.new(Attribute)

        custom_class.define_method(:parse) do |item_head, columns|
          value = columns[attribute.to_sym]&.strip&.presence
          process_value.call(value)
        end

        [attribute.to_sym, custom_class.new(config)]
      }
    end

    def set_columns
      @columns = config
        .deep_fetch(:csv, :columns)
        .select { |_head, enabled| enabled }
        .keys
        .concat(config.deep_fetch(:csv, :custom_numeric_columns).keys)
        .concat(config.deep_fetch(:csv, :custom_text_columns).keys)
        .zip(string.split(config.deep_fetch(:csv, :column_separator)))
        .to_h
    end

    def ensure_head_column_present
      if @columns[:head].nil? || @columns[:head].strip.empty?
        raise InvalidItemError, "The Head column must not be blank"
      end
    end

    def item_hash(item_head)
      config
        .deep_fetch(:item, :template)
        .merge(config.deep_fetch(:csv, :custom_numeric_columns))
        .merge(config.deep_fetch(:csv, :custom_text_columns))
        .map { |attribute_name, default_value|
          attribute_parser = @attribute_parsers.fetch(attribute_name)
          parsed = attribute_parser.parse(item_head, @columns)

          [attribute_name, parsed || default_value]
        }.to_h
    end
  end
end
