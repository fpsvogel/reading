require_relative 'operation'
require_relative 'filter'
require_relative 'grouping'

module Reading
  module Stats
    # Gives statistics on an array of Items.
    class Query
      private attr_reader :input, :items, :config, :result_formatters, :pastel

      # @param input [String] the query string.
      # @param items [Array<Item>] the Items to be queried.
      # @param config [Hash] an entire config.
      # @param result_formatters [Boolean, Hash{Symbol => Proc}] to alter the
      #   appearance of results; keys should be from among the keys of
      #   Operation::ACTIONS. Pre-made formatters for terminal output are in
      #   terminal_result_formatters.rb.
      def initialize(input:, items:, config: Reading.default_config, result_formatters: {})
        @input = input
        @items = items
        @config = config
        @result_formatters = result_formatters
        @pastel = Pastel.new
      end

      # Parses the query and returns the result.
      # @return [Object]
      def result
        filtered_items = Stats::Filter.filter(input, items, config)
        grouped_items = Grouping.group(input, filtered_items, config)

        Operation.execute(input, grouped_items, result_formatters || {})
      rescue Reading::Error => e
        raise e.class, pastel.bright_red(e.message)
      end
    end
  end
end
