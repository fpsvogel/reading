module Reading
  module Parsing
    module Attributes
      # Transformer for the :rating item attribute.
      class Rating < Attribute
        # @param parsed_row [Hash] a parsed row (the intermediate hash).
        # @param _head_index [Integer] current item's position in the Head column.
        # @return [Integer, Float]
        def transform_from_parsed(parsed_row, _head_index)
          rating = parsed_row[:rating]&.dig(:number)

          Integer(rating, exception: false) || Float(rating, exception: false)
        end
      end
    end
  end
end
