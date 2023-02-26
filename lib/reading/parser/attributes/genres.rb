module Reading
  module Parser
    module Attributes
      class Genres < Attribute
        using Util::HashArrayDeepFetch

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
  end
end
