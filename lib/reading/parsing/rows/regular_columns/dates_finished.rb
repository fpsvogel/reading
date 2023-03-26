module Reading
  module Parsing
    module Rows
      module Regular
        # See https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#dates-started-and-dates-finished-columns
        class DatesFinished < Column
          def self.segment_separator
            /,\s*/
          end

          def self.regexes(segment_index)
            [%r{\A
              (?<date>\d{4}/\d\d?/\d\d?)
            \z}x]
          end
        end
      end
    end
  end
end
