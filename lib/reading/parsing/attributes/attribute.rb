module Reading
  module Parsing
    module Attributes
      # The base class for all the attribute in parsing/attributes, each of which
      # extracts an attribute from a parsed row. Together they transform the
      # parsed row (an intermediate hash) into item attributes, as in
      # Config#default_config[:item][:template].
      class Attribute
        private attr_reader :config

        # @param config [Hash] an entire config.
        def initialize(config)
          @config = config
        end

        # Extracts this attribute's value from a parsed row.
        # @param parsed_row [Hash] a parsed row (the intermediate hash).
        # @param head_index [Integer] current item's position in the Head column.
        # @return [Object]
        def transform_from_parsed(parsed_row, head_index)
          raise NotImplementedError, "#{self.class} should have implemented #{__method__}"
        end
      end
    end
  end
end
