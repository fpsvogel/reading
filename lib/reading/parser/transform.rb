# require_relative "attributes/attribute" # RM
require_relative "attributes/rating"
require_relative "attributes/author"
require_relative "attributes/title"
require_relative "attributes/genres"
require_relative "attributes/variants"
require_relative "attributes/experiences"
require_relative "attributes/notes"

module Reading
  module Parser
    class Transform
      using Util::HashArrayDeepFetch

      attr_reader :config
      private attr_reader :attribute_classes

      def initialize(config)
        @config = config

        set_attribute_classes
      end

      def transform_intermediate_hash_to_item_hashes(parsed)
        parsed[:head].map.with_index { |_head, head_index|
          config.deep_fetch(:item, :template).map { |attribute_name, default_value|
            attribute_class = attribute_classes.fetch(attribute_name)
            extracted_value = attribute_class.extract(parsed, head_index, config)

            [attribute_name, extracted_value || default_value]
          }.to_h
        }
      end

      private

      def set_attribute_classes
        @attribute_classes ||= config.deep_fetch(:item, :template).map { |attribute_name, _default|
          attribute_name_camelcase = attribute_name.to_s.split("_").map(&:capitalize).join
          attribute_class = Attributes.const_get(attribute_name_camelcase)

          [attribute_name, attribute_class]
        }.to_h
      end
    end
  end
end
