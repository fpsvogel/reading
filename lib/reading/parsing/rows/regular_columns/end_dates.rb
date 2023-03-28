module Reading
  module Parsing
    module Rows
      module Regular
        # See https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#start-dates-and-end-dates-columns
        class EndDates < Column
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
