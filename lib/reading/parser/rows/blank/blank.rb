module Reading
  module Parser
    module Rows
      class Blank
        class Blank < Column
          def self.regexes(segment_index)
            [%r{\A
              (
                \\ # comment character
                \s*
                .*
              )?
            \z}x]
          end
        end
      end
    end
  end
end
