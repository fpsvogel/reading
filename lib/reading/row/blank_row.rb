require_relative "row"

module Reading
  # An empty or commented-out row. A null object which returns an empty array.
  class BlankRow < Row
    using Util::HashArrayDeepFetch

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
