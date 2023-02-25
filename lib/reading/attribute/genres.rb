require_relative "attribute"

module Reading
  using Util::HashArrayDeepFetch

  class Genres < Attribute
    def parse
      return nil unless columns[:genres]

      columns[:genres]
        .split(config.deep_fetch(:csv, :separator))
        .map(&:strip)
        .map(&:downcase)
        .map(&:presence)
        .compact.presence
    end
  end
end
