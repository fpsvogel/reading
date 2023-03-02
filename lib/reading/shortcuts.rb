require_relative "parser/csv"

module Reading
  # Parses a CSV file or string. See Parser::CSV#initialize and #parse for details.
  def self.parse(...)
    csv = Parser::CSV.new(...)
    csv.parse
  end
end
