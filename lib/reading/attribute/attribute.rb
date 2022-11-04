module Reading
  class Row
    # A base class that contains behaviors common to ___Attribute classes.
    class Attribute
      def initialize(config)
        @config = config
      end

      def parse
        raise NotImplementedError, "#{self.class} should have implemented #{__method__}"
      end
    end
  end
end
