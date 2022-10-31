require_relative "../../errors"
require_relative "../../util/blank"
require_relative "../../util/deep_fetch"
require_relative "row"
require_relative "../parse_attribute/parse_attributes"

module Reading
  class CSV
    # A function that parses a normal row in a CSV reading log into an array of
    # hashes of item data.
    class RegularRow < Row
      using Util::DeepFetch

      private

      def after_initialize
        setup_parse_attributes
      end

      def before_parse(row)
        set_columns(row)
        ensure_name_column_present
      end

      def multi_items_to_be_split_by_format_emojis
        @columns[:name]
      end

      def setup_parse_attributes
        @parse_attributes ||= @config.deep_fetch(:item, :template).map { |attribute, _default|
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
        @config.deep_fetch(:csv, :"custom_#{type}_columns").map { |attribute, _default_value|
          custom_class = Class.new ParseAttribute

          custom_class.define_method :call do |item_name, columns|
            value = columns[attribute.to_sym]&.strip&.presence
            process_value.call(value)
          end

          [attribute.to_sym, custom_class.new(@config)]
        }
      end

      def set_columns(row)
        @columns = @config
          .deep_fetch(:csv, :columns)
          .select { |_name, enabled| enabled }
          .keys
          .concat(@config.deep_fetch(:csv, :custom_numeric_columns).keys)
          .concat(@config.deep_fetch(:csv, :custom_text_columns).keys)
          .zip(row.split(@config.deep_fetch(:csv, :column_separator)))
          .to_h
      end

      def ensure_name_column_present
        if @columns[:name].nil? || @columns[:name].strip.empty?
          raise InvalidItemError, "The Name column must not be blank"
        end
      end

      def item_data(name)
        @config
          .deep_fetch(:item, :template)
          .merge(@config.deep_fetch(:csv, :custom_numeric_columns))
          .merge(@config.deep_fetch(:csv, :custom_text_columns))
          .map { |attribute, default_value|
            parsed = @parse_attributes.deep_fetch(attribute).call(name, @columns)

            [attribute, parsed || default_value]
          }.to_h
      end
    end
  end
end
