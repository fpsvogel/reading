module Reading
  module Parsing
    module Attributes
      class Experiences < Attribute
        class HistoryTransformer
          private attr_reader :config, :parsed_row, :head_index

          def initialize(parsed_row, config)
            @config = config
            @parsed_row = parsed_row
          end

          def transform

          end
        end
      end
    end
  end
end
