module Reading
  module Parsing
    module Attributes
      class Notes
        def initialize(_config)
        end

        def extract(parsed, _head_index)
          parsed[:notes]&.map { |note|
            {
              blurb?: note.has_key?(:note_blurb),
              private?: note.has_key?(:note_private),
              content: note[:note_regular] || note[:note_blurb] || note[:note_private],
            }
          }
        end
      end
    end
  end
end
