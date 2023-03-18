module Reading
  module Parser
    module Attributes
      class Title
        def self.extract(parsed, head_index, _config)
          parsed[:head][head_index][:title]
        end
      end
    end
  end
end
