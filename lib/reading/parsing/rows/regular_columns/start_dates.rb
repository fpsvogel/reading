module Reading
  module Parsing
    module Rows
      module Regular
        # See https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#start-dates-and-end-dates-columns
        class StartDates < Column
          def self.segment_separator
            /,\s*/
          end

          def self.regexes(segment_index)
            # dnf/progress, date, variant number, group
            [%r{\A
              (
                #{Column::SHARED_REGEXES[:progress]}
                (\s+|\z)
              )?
              (
                (
                  (?<date>\d{4}/\d\d?/\d\d?)
                  |
                  (?<planned>\?\?)
                )
                (\s+|\z)
              )?
              (
                v(?<variant>\d)
                (\s+|\z)
              )?
              (
                🤝🏼(?<group>.+)
              )?
            \z}x]
          end
        end
      end
    end
  end
end
