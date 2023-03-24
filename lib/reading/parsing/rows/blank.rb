module Reading
  module Parsing
    module Rows
      module Blank
        using Util::HashArrayDeepFetch

        def self.column_classes
          []
        end

        def self.match?(row_string, config)
          row_string.lstrip.start_with?(config.fetch(:comment_character)) &&
            !row_string.match?(config.deep_fetch(:regex, :formats))
        end
      end
    end
  end
end
