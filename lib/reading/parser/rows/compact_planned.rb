require_relative "column"
require_relative "compact_planned_columns/head"
require_relative "regular_columns/sources"

module Reading
  module Parser
    module Rows
      module CompactPlanned
        using Util::HashArrayDeepFetch

        def self.column_classes
          [Head, Regular::Sources]
        end

        def self.match?(row_string, config)
          comment = /\A\s*\\/
          row_string.match?(comment) && row_string.match?(config.deep_fetch(:regex, :formats))
        end
      end
    end
  end
end
