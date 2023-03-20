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
      using Util::HashCompactByTemplate

      attr_reader :config
      private attr_reader :attributes

      def initialize(config)
        @config = config

        set_attributes
      end

      def transform_intermediate_hash_to_item_hashes(parsed)
        if parsed[:head].blank?
          raise InvalidHeadError, "Blank or missing Head column"
        end

        template = config.fetch(:item_template)

        parsed[:head].map.with_index { |_head, head_index|
          template.map { |attribute_name, default_value|
            attribute = attributes.fetch(attribute_name)
            extracted_value = attribute.extract(parsed, head_index)

            [attribute_name, extracted_value || default_value]
          }.to_h
          .compact_by(template:)
        }
      end

      private

      def set_attributes
        @attributes ||= config.fetch(:item_template).map { |attribute_name, _default|
          attribute_name_camelcase = attribute_name.to_s.split("_").map(&:capitalize).join
          attribute_class = Attributes.const_get(attribute_name_camelcase)

          [attribute_name, attribute_class.new(config)]
        }.to_h
      end
    end
  end
end
