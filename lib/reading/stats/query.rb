require_relative 'operation'
require_relative 'filter'
require_relative 'grouping'

# average rating of in progress 3 star audiobook dnfs from Hoopla by genre

# OPERATIONS:
# ✅ average rating(s)
# ✅ average length(s)
# ✅ average amount(s)
# ✅ total item(s)
# ✅ total amount(s)
# ✅ top/bottom 5 rating(s)
# ✅ top/bottom 5 length(s)
# ✅ top/bottom 5 amount(s)
# ✅ top/bottom 5 speed(s)

# ITEM FILTERS
# ✅genre(s)=/!=
# ✅rating(s)=/>/>=/</<=/!=
# ✅format(s)=/!=
# ✅source(s)=/!=/~/!~
# ✅title(s)=/!=/~/!~
# ✅author(s)=/!=/~/!~
# ✅series=/!=/~/!~
# ✅note(s)=/!=/~/!~
# ✅status(es)=/!=
# ✅length(s)=/>/>=/</<=/!=
# ✅done(s)=/>/>=/</<=/!=
# ✅experience(s)=/>/>=/</<=/!=
# ✅date(s)=/>/>=/</<=/!=
# ✅end-date(s)=/>/>=/</<=/!=

# RESULT GROUPINGS
# ✅by month(s)
# ✅by year(s)
# ✅by genre(s)
# ✅by rating(s)
# ✅by format(s)
# ✅by source(s)
# ✅by length(s)

module Reading
  module Stats
    # Gives statistics on an array of Items.
    class Query
      private attr_reader :input, :items, :result_formatters

      # @param input [String] the query string.
      # @param items [Array<Item>] the Items to be queried.
      # @param result_formatters [Boolean, Hash{Symbol => Proc}] to alter the
      #   appearance of results; keys should be from among the keys of
      #   Operation::ACTIONS. Pre-made formatters for terminal output are in
      #   terminal_result_formatters.rb.
      def initialize(input:, items:, result_formatters: {})
        @input = input
        @items = items
        @result_formatters = result_formatters
      end

      # Parses the query and returns the result.
      # @return [Object]
      def result
        filtered_items = Stats::Filter.filter(input, items)
        grouped_items = Grouping.group(input, filtered_items)

        Operation.execute(input, grouped_items, result_formatters || {})
      end
    end
  end
end
