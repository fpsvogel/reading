require "pastel"
require_relative "operation"
require_relative "filter"
require_relative "grouping"

module Reading
  module Stats
    # Gives statistics on an array of Items.
    class Query
      private attr_reader :input, :items, :result_formatters, :pastel

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
        @pastel = Pastel.new
      end

      # Parses the query and returns the result.
      # @return [Object]
      def result
        filtered_items = Stats::Filter.filter(input, items)
        grouped_items = Grouping.group(input, filtered_items)

        Operation.execute(input, grouped_items, result_formatters || {})
      rescue Reading::Error => e
        raise e.class, pastel.bright_red(e.message)
      end
    end
  end
end
