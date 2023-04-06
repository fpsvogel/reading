require_relative "reading/parsing/csv"
require_relative "reading/time_length.rb"

# The gem's public API. See https://github.com/fpsvogel/reading#usage

module Reading
  # Parses a CSV file or string. See Parsing::CSV#initialize and #parse for details.
  def self.parse(...)
    csv = Parsing::CSV.new(...)
    csv.parse
  end

  # @param string [String] a time duration in "h:mm" format.
  # @return [Reading::TimeLength]
  def self.time(string)
    Reading::TimeLength.parse(string)
  end
end
