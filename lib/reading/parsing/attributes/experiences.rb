require "date"
require_relative "experiences/history_transformer"
require_relative "experiences/dates_and_head_transformer"

module Reading
  module Parsing
    module Attributes
      # Transformer for the :experiences item attribute.
      class Experiences < Attribute
        using Util::HashArrayDeepFetch
        using Util::HashDeepMerge

        # @param parsed_row [Hash] a parsed row (the intermediate hash).
        # @param head_index [Integer] current item's position in the Head column.
        # @return [Array<Hash>] an array of experiences; see
        #   Config#default_config[:item][:template][:experiences]
        def transform_from_parsed(parsed_row, head_index)
          if !parsed_row[:history].blank?
            return HistoryTransformer.new(parsed_row, head_index).transform
          end

          DatesAndHeadTransformer.new(parsed_row, head_index).transform
        end
      end
    end
  end
end
