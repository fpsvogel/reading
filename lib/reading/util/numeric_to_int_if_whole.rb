module Reading
  module Util
    # Same as #to_int but only applies if the result is equal to the original number.
    module NumericToIntIfWhole
      refine Numeric do
        def to_int_if_whole
          if is_a?(Float) && nan?
            0
          else
            to_int == self ? to_int : self
          end
        end
      end
    end
  end
end
