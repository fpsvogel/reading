module Reading
  module Parsing
    module Rows
      module Regular
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
