require_relative "attributes/shared"
require_relative "attributes/attribute"
require_relative "attributes/rating"
require_relative "attributes/author"
require_relative "attributes/title"
require_relative "attributes/genres"
require_relative "attributes/variants"
require_relative "attributes/experiences"
require_relative "attributes/notes"

module Reading
  module Parsing
    #
    # Transforms an intermediate hash (parsed from a CSV row) into item data.
    # While the intermediate hash mirrors the structure of a row, the output of
    # Transformer is based around item attributes, which are listed in
    # Config#default_config[:item][:template] and in the files in parsing/attributes.
    #
    class Transformer
      using Util::HashArrayDeepFetch
      using Util::HashCompactByTemplate

      private attr_reader :attributes

      def initialize
        set_attributes
      end

      # Transforms the intermediate hash of a row into item data.
      # @param parsed_row [Hash{Symbol => Hash, Array}] output from
      #   Parsing::Parser#parse_row_to_intermediate_hash.
      # @return [Array<Hash>] an array of Hashes like the template in
      #   Config#default_config[:item][:template].
      def transform_intermediate_hash_to_item_hashes(parsed_row)
        if parsed_row[:head].blank?
          raise InvalidHeadError, "Blank or missing Head column"
        end

        template = Config.hash.deep_fetch(:item, :template)

        parsed_row[:head].map.with_index { |_head, head_index|
          template.map { |attribute_name, default_value|
            attribute = attributes.fetch(attribute_name)
            transformed_value = attribute.transform_from_parsed(parsed_row, head_index)

            [attribute_name, transformed_value || default_value]
          }.to_h
          .compact_by(template:)
        }
      end

      private

      # Sets the attributes classes which do all the transforming work.
      # See parsing/attributes/*.
      def set_attributes
        @attributes ||= Config.hash.deep_fetch(:item, :template).map { |attribute_name, _default|
          attribute_name_camelcase = attribute_name.to_s.split("_").map(&:capitalize).join
          attribute_class = Attributes.const_get(attribute_name_camelcase)

          [attribute_name, attribute_class.new]
        }.to_h
      end
    end
  end
end
