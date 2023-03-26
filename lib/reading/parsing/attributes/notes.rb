module Reading
  module Parsing
    module Attributes
      class Notes < Attribute
        def extract(parsed_row, _head_index)
          parsed_row[:notes]&.map { |note|
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
