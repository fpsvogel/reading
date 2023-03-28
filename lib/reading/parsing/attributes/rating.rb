module Reading
  module Parsing
    module Attributes
      class Rating < Attribute
        def transform_from_parsed(parsed_row, _head_index)
          rating = parsed_row[:rating]&.dig(:number)

          Integer(rating, exception: false) || Float(rating, exception: false)
        end
      end
    end
  end
end
