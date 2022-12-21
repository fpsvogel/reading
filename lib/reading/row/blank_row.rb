require_relative "row"

module Reading
  # An empty or commented-out row. A null object which returns an empty array.
  class BlankRow < Row
    using Util::HashArrayDeepFetch

    # Whether the given CSV line is a blank row.
    # @param line [Reading::Line]
    # @return [Boolean]
    def self.match?(line)
      comment_char = line.csv.config.deep_fetch(:csv, :comment_character)

      line.string.strip.empty? ||
        line.string.strip.start_with?(comment_char)
    end

    # Overrides Row#parse.
    def parse
      []
    end
  end
end
