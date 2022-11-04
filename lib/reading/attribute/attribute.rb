module Reading
  class Row
    # A base class that contains behaviors common to ___Attribute classes.
    class Attribute
      private attr_reader :item_head, :columns, :config

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
