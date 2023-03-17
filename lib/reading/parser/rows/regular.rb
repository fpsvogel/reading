require_relative "regular/rating"
require_relative "regular/head"
require_relative "regular/sources"
require_relative "regular/dates_started"
require_relative "regular/dates_finished"
require_relative "regular/genres"
require_relative "regular/length"
require_relative "regular/notes"

module Reading
  module Parser
    module Rows
      module Regular
        def self.columns
          [Rating, Head, Sources, DatesStarted, DatesFinished, Genres, Length, Notes]
        end

        def self.match?(row_string, config)
          comment = /\A\s*\\/
          !row_string.match?(comment)
        end
      end
    end
  end
end
