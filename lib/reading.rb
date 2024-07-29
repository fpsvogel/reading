Dir[File.join(__dir__, "reading", "util", "*.rb")].each { |file| require file }
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
#                                         (filtered    (stats input*
#        (CSV input)             (Items)   Items)       and Items)    (results)
#             |                   Λ   |        Λ             |          Λ
#             V                   |   V        |             V          |
#          ::parse                |  ::filter  |           ::stats      |
#             |                   |        |   |             |          |
#             |                   |        |   |             |          |
#             |                   |        |   |             |          |
#        Parsing::CSV ---------> Item      Filter            Stats::Query
#            /   \               / \                          / | \
#           /     \    Item::View  Item::TimeLength          /  |  \
#          /       \                                        /   |   \
# Parsing::Parser  Parsing::Transformer           Stats::Filter |  Stats::Operation
#        |                 |                             Stats::Grouping
#  parsing/rows/*   parsing/attributes/*
#                                               * Stats input is either from the
#                                                 command line (via the `reading`
#                                                 command) or provided via Ruby
#                                                 code that uses this gem.
#                                                 Results likewise go either to
#                                                 stdout or to the gem user.
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

  # @return [Hash]
  def self.config
    Config.hash
  end

  # A shortcut for getting a time from a string.
  # @param string [String] a time duration in "h:mm" format.
  # @return [Item::TimeLength]
  def self.time(string)
    Item::TimeLength.parse(string)
  end
end
