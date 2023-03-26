module Reading
  module Parsing
    module Rows
      module Regular
        # See https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#rating-column
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
