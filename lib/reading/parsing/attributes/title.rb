module Reading
  module Parsing
    module Attributes
      # Transformer for the :title item attribute.
      class Title < Attribute
        # @param parsed_row [Hash] a parsed row (the intermediate hash).
        # @param head_index [Integer] current item's position in the Head column.
        # @return [String]
        def transform_from_parsed(parsed_row, head_index)
          title = parsed_row[:head][head_index][:title]

          if title.nil? || title.end_with?(" -")
            raise InvalidHeadError, "Missing title"
          end

          title
        end
      end
    end
  end
end
