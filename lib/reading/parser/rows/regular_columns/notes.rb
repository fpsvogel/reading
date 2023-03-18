module Reading
  module Parser
    module Rows
      module Regular
        class Notes < Column
          def self.segment_separator
            /\s*--\s*/
          end

          def self.flatten_segments?
            false
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
