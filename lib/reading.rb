require_relative "reading/parsing/csv"

# The gem's public API. See https://github.com/fpsvogel/reading#usage

module Reading
  # Parses a CSV file or string. See Parsing::CSV#initialize and #parse for details.
  def self.parse(...)
    csv = Parsing::CSV.new(...)
    csv.parse
  end
end
