module Reading
  module Parsing
    module Rows
      # A row that is a comment.
      module Comment
        using Util::HashArrayDeepFetch

        # No columns; comments are parsed as if the row were blank.
        # @return [Array]
        def self.column_classes
          []
        end

        # Starts with a comment character and does not include any format emojis.
        # (Commented rows that DO include format emojis are matched as compact
        # planned rows.)
        # @param row_string [String]
        # @param config [Hash]
        # @return [Boolean]
        def self.match?(row_string, config)
          row_string.lstrip.start_with?(config.fetch(:comment_character))
        end
      end
    end
  end
end
