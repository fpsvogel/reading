module Reading
  module Util
    # Same as #to_i but only applies if the result is equal to the original number.
    module NumericToIIfWhole
      refine Numeric do
        def to_i_if_whole
          to_i == self ? to_i : self
        end
      end
    end
  end
end
