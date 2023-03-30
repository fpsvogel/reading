module Reading
  module Parsing
    module Attributes
      # Transformer for the :genres item attribute.
      class Genres < Attribute
        # @param parsed_row [Hash] a parsed row (the intermediate hash).
        # @param head_index [Integer] current item's position in the Head column.
        # @return [Array<String>]
        def transform_from_parsed(parsed_row, head_index)
          (parsed_row[:genres] || parsed_row[:head][head_index][:genres])
            &.map { _1.is_a?(Hash) ? _1[:genre] : _1 }
        end
      end
    end
  end
end
