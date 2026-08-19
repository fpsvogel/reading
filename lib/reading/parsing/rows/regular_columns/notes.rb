module Reading
  module Parsing
    module Rows
      module Regular
        # See https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#notes-column
        # and https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#notes-column-special-notes
        class Notes < Column
          def self.segment_separator
            /\s*--\s*/
          end

          def self.regexes(segment_index)
            [%r{\A
              (?:(?<blurb>💬)|(?<private>🔒))?
              (?<date>\d{4}/\d\d?/\d\d?)?:?\s*
              (?:
                (?:
                  (?:downgraded|upgraded|updated|changed)?\s*rating
                  |
                  rating\s*(?:downgraded|upgraded|updated|changed)?
                )?
                (?:\s+from\s+)?
                (?:
                  (?<rating_from>\d)
                  \s+to\s+
                  (?<rating_to>\d)
                )
                (?:\s+because\s+|\s*[[:punct:]]\s*)?
              )?
              (?<content>.+)?
            \z}xi]
          end
        end
      end
    end
  end
end
