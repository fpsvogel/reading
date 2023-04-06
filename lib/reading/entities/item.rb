require_relative "../util/hash_to_struct"

module Reading
  module Entities
    # A wrapper for an item parsed from a CSV reading log, providing convenience
    # methods beyond what the parser's raw Hash output can provide.
    class Item
      using Util::HashToStruct
      extend Forwardable

      private attr_reader :struct

      def_delegators :struct,
        :rating, :author, :title, :genres, :variants, :experiences, :notes

      # @param hash [Hash] a parsed item like the template in
      #   Config#default_config[:item_template].
      def initialize(hash)
        @struct = hash.to_struct
      end
    end
  end
end
