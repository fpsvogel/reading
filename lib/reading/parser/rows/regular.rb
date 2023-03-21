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
  module Parser
    module Rows
      module Regular
        def self.column_classes
          [Rating, Head, Sources, DatesStarted, DatesFinished, Genres, Length, Notes]
        end

        def self.match?(row_string, config)
          !row_string.lstrip.start_with?(config.fetch(:comment_character))
        end
      end
    end
  end
end
