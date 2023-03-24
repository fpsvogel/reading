module Reading
  module Parsing
    module Attributes
      class Genres
        def initialize(_config)
        end

        def extract(parsed, head_index)
          (parsed[:genres] || parsed[:head][head_index][:genres])
            &.map { _1.is_a?(Hash) ? _1[:genre] : _1 }
        end
      end
    end
  end
end
