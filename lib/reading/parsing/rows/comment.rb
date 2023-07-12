module Reading
  module Parsing
    module Rows
      # A row that is a comment.
      module Comment
        using Util::HashArrayDeepFetch

        # No columns; parsed as if the row were blank.
        # @return [Array]
        def self.column_classes
          []
        end

        # Starts with a comment character. Note: this must be called *after*
        # calling ::match? on Rows::CompactPlanned and Rows::CustomConfig,
        # because those check for starting with a comment character too.
        # @param row_string [String]
        # @return [Boolean]
        def self.match?(row_string)
          row_string.lstrip.start_with?(Config.hash.fetch(:comment_character))
        end
      end
    end
  end
end
