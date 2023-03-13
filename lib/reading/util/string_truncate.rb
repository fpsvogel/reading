module Reading
  module Util
    module StringTruncate
      refine String do
        def truncate(length)
          ellipsis = "..."
          if length < self.length - ellipsis.length
            "#{self[0...length]}#{ellipsis}"
          else
            self
          end
        end
      end
    end
  end
end
