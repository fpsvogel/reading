require_relative "rows/compact_planned_row"
require_relative "rows/blank_row"
require_relative "rows/regular_row"

module Reading
  module Parser
    # A bridge between rows as strings and as parsable Rows, used whenever the
    # context of the line in the CSV is needed, e.g. converting a line to a Row,
    # or adding a CSV line to a Row parsing error.
    class Line
      attr_reader :string, :csv

      def initialize(string, csv)
        @string = string.dup.force_encoding(Encoding::UTF_8).strip
        @csv = csv
      end

      def to_row
        return Rows::CompactPlannedRow.new(self) if Rows::CompactPlannedRow.match?(self)
        return Rows::BlankRow.new(self) if Rows::BlankRow.match?(self)
        Rows::RegularRow.new(self)
      end
    end
  end
end
