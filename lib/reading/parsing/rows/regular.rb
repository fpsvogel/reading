require_relative "column"
require_relative "regular_columns/rating"
require_relative "regular_columns/head"
require_relative "regular_columns/sources"
require_relative "regular_columns/dates_started"
require_relative "regular_columns/dates_finished"
require_relative "regular_columns/genres"
require_relative "regular_columns/length"
require_relative "regular_columns/notes"

module Reading
  module Parsing
    module Rows
      # A normal row of (usually) one item.
      module Regular
        # The columns that are possible in this type of row.
        # @return [Array<Class>]
        def self.column_classes
          [Rating, Head, Sources, DatesStarted, DatesFinished, Genres, Length, Notes]
        end

        # Does not start with a comment character.
        # @param row_string [String]
        # @param config [Hash]
        # @return [Boolean]
        def self.match?(row_string, config)
          !row_string.lstrip.start_with?(config.fetch(:comment_character))
        end
      end
    end
  end
end
