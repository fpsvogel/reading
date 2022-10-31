module Reading
  class CSV
    class Row
      # A base class that contains behaviors common to Parse___ classes for attributes.
      class ParseAttribute
        def initialize(config)
          @config = config
        end
      end
    end
  end
end
