module Reading
  module Parser
    module Attributes
      class Author
        def initialize(_config)
        end

        def extract(parsed, head_index)
          parsed[:head][head_index][:author]
        end
      end
    end
  end
end
