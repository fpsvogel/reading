module Reading
  module Parsing
    module Attributes
      # The base class for all the attributes in parsing/attributes.
      class Attribute
        private attr_reader :config

        # @param config [Hash] an entire config.
        def initialize(config)
          @config = config
        end

        # Extracts this attribute's value from a parsed row.
        # @param parsed_row [Hash] a parsed row (the intermediate hash).
        # @param head_index [Integex] the position of the current item in the
        #   Head column.
        # @return [Object]
        def extract(parsed_row, head_index)
          raise NotImplementedError, "#{self.class} should have implemented #{__method__}"
        end
      end
    end
  end
end
