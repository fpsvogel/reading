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
              (?:(?<blurb>💬)|(?<private>🔒))?(?<content>.+)
            \z}x]
          end
        end
      end
    end
  end
end
