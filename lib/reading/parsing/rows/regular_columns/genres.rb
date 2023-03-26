module Reading
  module Parsing
    module Rows
      module Regular
        # See https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#genres-column
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
