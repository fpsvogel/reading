require_relative 'operation'
require_relative 'result_formatters'
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
      # @param result_formatters [Boolean, Hash{Symbol => Proc}] if true, alters
      #   appearance of results using the formatters in result_formatters.rb; if
      #   false, does not use any formatters; if a Hash is provided, uses it as
      #   custom formatters, in which case keys should be from among the keys of
      #   Operation::ACTIONS.
      def initialize(input:, items:, result_formatters: false)
        @input = input
        @items = items

        if result_formatters == true
          @result_formatters = ResultFormatters::DEFAULT_RESULT_FORMATTERS
        elsif result_formatters
          @result_formatters = result_formatters
        end
      end

      # Parses the query and returns the result.
      # @return [Object]
      def result
        Operation.execute(input, items, result_formatters || {})
      end
    end
  end
end
