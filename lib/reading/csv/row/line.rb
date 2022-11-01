require_relative "compact_planned_row"
require_relative "blank_row"
require_relative "regular_row"

module Reading
  class CSV
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
        return CompactPlannedRow.new(self) if CompactPlannedRow.match?(self)
        return BlankRow.new(self) if BlankRow.match?(self)
        RegularRow.new(self)
      end
    end
  end
end
