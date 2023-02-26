module Reading
  module Parser
    module Attributes
      class Rating < Attribute
        def parse
          return nil unless columns[:rating]

          rating = columns[:rating].strip
          return nil if rating.empty?

          Integer(rating, exception: false) ||
            Float(rating, exception: false) ||
            (raise InvalidRatingError, "Invalid rating")
        end
      end
    end
  end
end
