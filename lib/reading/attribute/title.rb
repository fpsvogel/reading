require_relative "attribute"

module Reading
  using Util::StringRemove
  using Util::HashArrayDeepFetch

  class Title < Attribute
    def parse
      if item_head.end_with?(config.deep_fetch(:csv, :short_separator).rstrip)
        raise InvalidHeadError, "Missing title? Head column ends in a separator"
      end

      item_head
        .remove(/\A#{config.deep_fetch(:csv, :regex, :formats)}/)
        .remove(/.+#{config.deep_fetch(:csv, :short_separator)}/)
        .remove(/#{config.deep_fetch(:csv, :long_separator)}.+\z/)
        .strip
        .presence || (raise InvalidHeadError, "Missing title")
    end
  end
end
