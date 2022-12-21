module Reading
  module Util
    module StringTruncate
      refine String do
        def truncate(max, padding: 0, min: 30)
          end_index = max - padding
          end_index = min if end_index < min
          self.length + padding > max ? "#{self[0...end_index]}..." : self
        end
      end
    end
  end
end
