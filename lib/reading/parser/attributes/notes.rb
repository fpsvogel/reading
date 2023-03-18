module Reading
  module Parser
    module Attributes
      class Notes
        def self.extract(parsed, head_index, _config)
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
