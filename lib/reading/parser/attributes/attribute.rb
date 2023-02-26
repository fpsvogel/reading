module Reading
  module Parser
    module Attributes
      # A base class that contains behaviors common to other classes in Attributes.
      class Attribute
        private attr_reader :item_head, :columns, :config

        # @param item_head [String] see Row#item_heads for a definition.
        # @param columns [Array<String>] the CSV row split into columns.
        # @param config [Hash]
        def initialize(item_head: nil, columns: nil, config:)
          unless item_head || columns
            raise ArgumentError, "Either item_head or columns must be given to an Attribute."
          end

          @item_head = item_head
          @columns = columns
          @config = config
        end

        def parse
          raise NotImplementedError, "#{self.class} should have implemented #{__method__}"
        end
      end
    end
  end
end
