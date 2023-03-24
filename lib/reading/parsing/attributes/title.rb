module Reading
  module Parsing
    module Attributes
      class Title
        def initialize(_config)
        end

        def extract(parsed, head_index)
          title = parsed[:head][head_index][:title]

          if title.nil? || title.end_with?(" -")
            raise InvalidHeadError, "Missing title"
          end

          title
        end
      end
    end
  end
end
