module Reading
  module Parsing
    module Rows
      module Regular
        # See  https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#length-column
        class Length < Column
          def self.regexes(segment_index)
            [%r{\A
              # length
              (
                (
                  (?<length_pages>\d+)p?
                  |
                  (?<length_time>\d+:\d\d)
                )
                (\s+|\z)
              )
              # each and repetitions are used in conjunction with the History column
              # each
              (
                (?<each>each)
                (\s+|\z)
              )?
              # repetitions
              (
                x
                (?<repetitions>\d+)
              )?
            \z}x]
          end
        end
      end
    end
  end
end
