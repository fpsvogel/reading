module Reading
  module Parsing
    module Attributes
      class Author < Attribute
        def extract(parsed_row, head_index)
          parsed_row[:head][head_index][:author]
        end
      end
    end
  end
end
