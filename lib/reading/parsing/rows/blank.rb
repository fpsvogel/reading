module Reading
  module Parsing
    module Rows
      # A row that is a blank line.
      module Blank
        using Util::HashArrayDeepFetch

        # No columns.
        # @return [Array]
        def self.column_classes
          []
        end

        # Is a blank line.
        # @param row_string [String]
        # @return [Boolean]
        def self.match?(row_string)
          row_string == "\n"
        end
      end
    end
  end
end
