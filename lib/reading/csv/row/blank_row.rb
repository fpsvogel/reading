require_relative "../../util/deep_fetch"
require_relative "../../util/blank"
require_relative "row"

module Reading
  class CSV
    # An empty or commented-out row. A null object which returns an empty array.
    class BlankRow < Row
      using Util::DeepFetch

      def self.match?(line)
        comment_char = line.csv.config.deep_fetch(:csv, :comment_character)

        line.string.strip.empty? ||
          line.string.strip.start_with?(comment_char)
      end

      def parse
        []
      end
    end
  end
end
