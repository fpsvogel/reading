module Reading
  module Parser
    module Rows
      module Blank
        using Util::HashArrayDeepFetch

        def self.column_classes
          []
        end

        def self.match?(row_string, config)
          comment = /\A\s*\\/
          row_string.match?(comment) && !row_string.match?(config.deep_fetch(:regex, :formats))
        end
      end
    end
  end
end
