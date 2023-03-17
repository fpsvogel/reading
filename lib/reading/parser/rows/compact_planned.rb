require_relative "compact_planned/head"
require_relative "regular/sources"

module Reading
  module Parser
    module Rows
      module CompactPlanned
        using Util::HashArrayDeepFetch

        def self.columns
          [Head, Regular::Sources]
        end

        def self.match?(row_string, config)
          comment = /\A\s*\\/
          row_string.match?(comment) && row_string.match?(config.deep_fetch(:regex, :formats))
        end
      end
    end
  end
end
