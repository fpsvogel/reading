module Reading
  module Parser
    module Attributes
      # A base class that contains behaviors common to other classes in Attributes.
      class Attribute
        attr_reader :config

        # @param config [Hash]
        def initialize(config:)
          @config = config
        end

        def transform(parsed)
          raise NotImplementedError, "#{self.class} should have implemented #{__method__}"
        end
      end
    end
  end
end
