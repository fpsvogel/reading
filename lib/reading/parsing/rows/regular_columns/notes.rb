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
            [
              # blurb note
              %r{\A
                💬\s*(?<note_blurb>.+)
              \z}x,
              # private note
              %r{\A
                🔒\s*(?<note_private>.+)
              \z}x,
              # regular note
              %r{\A
                (?<note_regular>.+)
              \z}x,
            ]
          end
        end
      end
    end
  end
end
