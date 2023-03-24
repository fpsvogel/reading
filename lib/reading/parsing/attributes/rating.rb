module Reading
  module Parsing
    module Attributes
      class Rating
        def initialize(_config)
        end

        def extract(parsed, _head_index)
          rating = parsed[:rating]&.dig(:number)

          Integer(rating, exception: false) || Float(rating, exception: false)
        end
      end
    end
  end
end
