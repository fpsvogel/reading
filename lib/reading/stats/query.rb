module Reading
  module Stats
    # Gives statistics on an array of Items.
    class Query
      private attr_reader :input, :items

      # @param input [String] the statistics query.
      # @param items [Array<Item>] the Items to be queried.
      def initialize(input:, items:)
        @input = input
        @items = items
      end

      # Parses the query and returns the result.
      # @return #TODO
      def result
      end
    end
  end
end
