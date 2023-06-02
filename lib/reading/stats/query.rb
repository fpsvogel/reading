require_relative 'operation'
# require_relative 'filter'
# require_relative 'group'

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

# INPUT FILTERS
# genre(s)=
# rating(s)=/>/>=/</<=
# format(s)=
# source(s)=
# status(es)=
# length(s)=/>/>=/</<=
# year(s)=
# progress(es)=/>/>=/</<=
#   ->(item) { item.done? && (progress = item.experiences.last.spans.last.progress) && progress < 1 }

# OUTPUT GROUPINGS
# group by month
# group by year
# group by genre
# group by rating
# group by format
# group by source
# group by length

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
        Operation.execute(input, items, result_formatters || {})
      end
    end
  end
end
