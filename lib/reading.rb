Gem.find_files("reading/util/*.rb").each { |f| require f }
require_relative "reading/errors"
require_relative "reading/config"
require_relative "reading/parsing/csv"
require_relative "reading/filter"
require_relative "reading/stats/query"
require_relative "reading/item/time_length.rb"

# The gem's public API. See https://github.com/fpsvogel/reading#usage
#
# Architectural overview:
#
#                 (CSV input)                    (Items)   (filtered Items)
#                      |                          Λ   |           Λ
#                      |                          |   ·---.       |
#                      |                          |       |       |
#                      V                          |       V       |
#                   ::parse                       |     ::filter  |
#                      |                          |          |    |
#                      |            .----------> Item        Filter
#  Config,             |           /             / \
#  errors.rb ----- Parsing::CSV --·    Item::View  Item::TimeLength
#                     / \
#      Parsing::Parser  Parsing::Transformer
#             |                 |
#       parsing/rows/*   parsing/attributes/*
#
module Reading
  # Parses a CSV file or string. See Parsing::CSV#initialize and #parse for details.
  def self.parse(...)
    csv = Parsing::CSV.new(...)
    csv.parse
  end

  # Filters an array of Items. See Filter::by for details.
  def self.filter(...)
    Filter.by(...)
  end

  # Returns statistics on Items. See Stats::Query#initialize and #result for details.
  def self.stats(...)
    query = Stats::Query.new(...)
    query.result
  end

  # The default config.
  # @return [Hash]
  def self.default_config
    Config.new.hash
  end

  # A shortcut for getting a time from a string.
  # @param string [String] a time duration in "h:mm" format.
  # @return [Item::TimeLength]
  def self.time(string)
    Item::TimeLength.parse(string)
  end
end
