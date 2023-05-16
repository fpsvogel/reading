module Reading
  module Stats
    # Gives statistics on an array of Items.
    class Query
      private attr_reader :input, :items, :config

      # @param input [String] the statistics query.
      # @param items [Array<Item>] the Items to be queried.
      def initialize(input:, items:, config:)
        @input = input
        @items = items
        @config = Config.new(config).hash
      end

      # Parses the query and returns the result.
      # @return #TODO
      def result
        library = Library.new(items, config)

        Command
          .parse(input, config)
          .result(library)
          .output(config)
      end
    end
  end
end
