module Reading
  module Util
    # Shortens the String to a given length.
    module StringTruncate
      refine String do
        # @param length [Integer]
        # @return [String]
        def truncate(length)
          if length < self.length - ELLIPSIS.length
            "#{self[0...length]}#{ELLIPSIS}"
          else
            self
          end
        end
      end

      private

      ELLIPSIS = "...".freeze
    end
  end
end
