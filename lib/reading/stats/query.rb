require_relative "operation"
# require_relative "filter"
# require_relative "group"

# average rating of in progress 3 star audiobook dnfs from Hoopla by genre

# OPERATIONS:
# ✅ average rating(s)
# ✅ average length(s)
# ✅ average amount(s)
# ✅ total item(s)
# ✅ total amount(s)
# ✅ top/bottom 5 rating(s)
# ✅ top/bottom 5 length(s)
# top/bottom 5 amount(s)
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
      private attr_reader :input, :items#, :config

      # @param input [String] the query string.
      # @param items [Array<Item>] the Items to be queried.
      # @param config [Hash] an entire config.
      def initialize(input:, items:, config: {})
        @input = input
        @items = items
        # @config = Config.new(config).hash
      end

      # Parses the query and returns the result.
      # @return [Object]
      def result
        Operation.execute(input, items)
      end
    end
  end
end
