require "date"
require_relative "experiences/history_transformer"
require_relative "experiences/dates_and_head_transformer"

module Reading
  module Parsing
    module Attributes
      class Experiences < Attribute
        using Util::HashArrayDeepFetch
        using Util::HashDeepMerge

        def transform_from_parsed(parsed_row, head_index)
          if !parsed_row[:history].blank?
            return HistoryTransformer.new(parsed_row, config).transform
          end

          DatesAndHeadTransformer.new(parsed_row, head_index, config).transform
        end
      end
    end
  end
end
