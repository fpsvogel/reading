module Reading
  module Parsing
    module Rows
      module Regular
        # See https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#notes-column
        # and https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#notes-column-special-notes
        class Notes < Column
          RATING_CHANGED_WORDS = %w[
            changed
            updated
            revised
            downgraded
            demoted
            lowered
            upgraded
            promoted
            raised
          ]

          def self.segment_separator
            /\s*--\s*/
          end

          def self.regexes(segment_index)
            [%r{\A
              (?:(?<blurb>💬)|(?<private>🔒))?
              (?<date>\d{4}/\d\d?/\d\d?)?:?\s*
              (?:
                (?:
                  (?:#{RATING_CHANGED_WORDS.join("|")})?\s*rating
                  |
                  rating\s*(?:#{RATING_CHANGED_WORDS.join("|")})?
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
