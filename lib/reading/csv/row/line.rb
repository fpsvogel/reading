require_relative "compact_planned_row"
require_relative "blank_row"
require_relative "regular_row"

module Reading
  class CSV
    # A bridge between CSV rows as strings and as Row subclasses. A factory of sorts.
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
