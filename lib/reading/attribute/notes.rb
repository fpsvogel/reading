require_relative "attribute"

module Reading
  using Util::StringRemove
  using Util::HashArrayDeepFetch

  class Notes < Attribute
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
