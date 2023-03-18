module Reading
  module Parser
    module Attributes
      class Notes
        def self.extract(parsed, head_index, _config)
          parsed[:notes].map { |note_type, note_string|
              {
                blurb?: note_type == :note_blurb,
                private?: note_type == :note_private,
                content: note_string,
              }
            }
        end
      end
    end
  end
end
