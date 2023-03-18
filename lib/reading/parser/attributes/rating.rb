module Reading
  module Parser
    module Attributes
      class Rating
        def self.extract(parsed, head_index, _config)
          rating = parsed[:head][head_index][:rating]

          Integer(rating, exception: false) || Float(rating, exception: false)
        end
      end
    end
  end
end
