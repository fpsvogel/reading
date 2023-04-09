require_relative "reading/parsing/csv"
require_relative "reading/item/time_length.rb"

# The gem's public API. See https://github.com/fpsvogel/reading#usage
#
# Architectural overview:
#
#                 (CSV input)
#                      |
#                   ::parse         -------------> Item -----------> (Item output)
#  Config,             |           /               / \
#  errors.rb ----- Parsing::CSV ---       Item::View  Item::TimeLength
#                     / \
#      Parsing::Parser  Parsing::Transformer
#             |                 |
#      parsing/attributes/*  parsing/rows/*
#
module Reading
  # Parses a CSV file or string. See Parsing::CSV#initialize and #parse for details.
  def self.parse(...)
    csv = Parsing::CSV.new(...)
    csv.parse
  end

  # A shortcut for getting a time from a string.
  # @param string [String] a time duration in "h:mm" format.
  # @return [Reading::Item::TimeLength]
  def self.time(string)
    Reading::Item::TimeLength.parse(string)
  end
end
