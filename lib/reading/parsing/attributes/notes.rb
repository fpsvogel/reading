module Reading
  module Parsing
    module Attributes
      # Transformer for the :notes item attribute.
      class Notes < Attribute
        # @param parsed_row [Hash] a parsed row (the intermediate hash).
        # @param _head_index [Integer] current item's position in the Head column.
        # @return [Array<Hash>] an array of notes; see
        #   Config#default_config[:item][:template][:notes]
        def transform_from_parsed(parsed_row, _head_index)
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
