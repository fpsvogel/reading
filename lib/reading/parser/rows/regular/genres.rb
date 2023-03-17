module Reading
  module Parser
    module Rows
      module Regular
        class Genres < Column
          def self.segment_separator
            /,\s*/
          end

          def self.regexes(segment_index)
            [%r{\A
              (?<genre>.+)
            \z}x]
          end
        end
      end
    end
  end
end
