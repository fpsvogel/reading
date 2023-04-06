require_relative "util/hash_to_data"

module Reading
  # A wrapper for an item parsed from a CSV reading log, providing convenience
  # methods beyond what the parser's raw Hash output can provide.
  class Item
    using Util::HashToData
    extend Forwardable

    private attr_reader :data

    def_delegators :data,
      :rating, :author, :title, :genres, :variants, :experiences, :notes

    # @param hash [Hash] a parsed item like the template in
    #   Config#default_config[:item_template].
    def initialize(hash)
      @data = hash.to_data
    end
  end
end
