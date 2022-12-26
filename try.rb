# A script that provides a quick way to see the output of a CSV string.
#
# Usage:
# Run this on the command line:
#   ruby try.rb "<CSV string>"`
#
# Example:
#   ruby try.rb "3|📕Trying|Lexpub 1970147288"


require_relative "lib/reading/csv"
require "amazing_print"

input = ARGV[0]
config = {}

if ARGV[1]
  enabled_columns = ARGV[1].split(",").map(&:strip).map(&:to_sym)
  config[:csv] = { enabled_columns: }
end

csv = Reading::CSV.new(input, config:)
items = csv.parse

ap items
