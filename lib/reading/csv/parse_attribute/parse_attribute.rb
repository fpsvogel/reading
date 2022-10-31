module Reading
  class CSV
      class ParseLine
        # ParseAttribute is a base class that contains behaviors common to Parse<Attribute> classes.
        class ParseAttribute
          def initialize(config)
            @config = config
          end
        end
    end
  end
end
