module Reading
  module Parser
    module Attributes
      class Notes < Attribute
        using Util::StringRemove
        using Util::HashArrayDeepFetch

        def parse
          return nil unless columns[:notes]

          columns[:notes]
            .presence
            &.chomp
            &.remove(/#{config.deep_fetch(:csv, :long_separator).rstrip}\s*\z/)
            &.split(config.deep_fetch(:csv, :long_separator))
            &.map { |string|
              {
                blurb?: !!string.delete!(config.deep_fetch(:csv, :blurb_emoji)),
                private?: !!string.delete!(config.deep_fetch(:csv, :private_emoji)),
                content: string.strip,
              }
            }
        end
      end
    end
  end
end
