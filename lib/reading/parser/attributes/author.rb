module Reading
  module Parser
    module Attributes
      class Author
        def self.extract(parsed, head_index, _config)
          parsed[:head][head_index][:author]
        end
      end
    end
  end
end

