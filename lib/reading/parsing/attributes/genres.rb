module Reading
  module Parsing
    module Attributes
      class Genres < Attribute
        def transform_from_parsed(parsed_row, head_index)
          (parsed_row[:genres] || parsed_row[:head][head_index][:genres])
            &.map { _1.is_a?(Hash) ? _1[:genre] : _1 }
        end
      end
    end
  end
end
