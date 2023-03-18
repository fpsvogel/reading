module Reading
  module Parser
    module Attributes
      class Genres
        def self.extract(parsed, head_index, _config)
          parsed[:genres]&.map { _1[:genre] }
        end
      end
    end
  end
end
