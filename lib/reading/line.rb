require_relative "row/multi_planned_row"
require_relative "row/blank_row"
require_relative "row/regular_row"

module Reading
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
      return MultiPlannedRow.new(self) if MultiPlannedRow.match?(self)
      return BlankRow.new(self) if BlankRow.match?(self)
      RegularRow.new(self)
    end
  end
end
