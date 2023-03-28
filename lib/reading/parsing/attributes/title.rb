module Reading
  module Parsing
    module Attributes
      class Title < Attribute
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
