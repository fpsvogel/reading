module Reading
  module Parser
    module Rows
      module Regular
        class Rating < Column
          def self.regexes(segment_index)
            # integer or float
            [/\A(?<number>\d+\.?\d*)?\z/]
          end
        end
      end
    end
  end
end
