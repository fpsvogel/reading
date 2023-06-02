require_relative 'column'
require_relative 'compact_planned_columns/head'
require_relative 'regular_columns/sources'
require_relative 'regular_columns/length'

module Reading
  module Parsing
    module Rows
      # A row that contains compact planned items.
      module CompactPlanned
        using Util::HashArrayDeepFetch

        # The columns that are possible in this type of row.
        # @return [Array<Class>]
        def self.column_classes
          [CompactPlanned::Head, Regular::Sources, Regular::Length]
        end

        # Starts with a comment character and includes one or more format emojis.
        # @param row_string [String]
        # @param config [Hash]
        # @return [Boolean]
        def self.match?(row_string, config)
          row_string.lstrip.start_with?(config.fetch(:comment_character)) &&
            row_string.match?(config.deep_fetch(:regex, :formats)) &&
            row_string.count(config.fetch(:column_separator)) <= column_classes.count - 1
        end
      end
    end
  end
end
