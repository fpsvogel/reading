module Reading
  module Parsing
    module Attributes
      # Transformer for the :author item attribute.
      class Author < Attribute
        # @param parsed_row [Hash] a parsed row (the intermediate hash).
        # @param head_index [Integer] current item's position in the Head column.
        # @return [String]
        def transform_from_parsed(parsed_row, head_index)
          parsed_row[:head][head_index][:author]
        end
      end
    end
  end
end
