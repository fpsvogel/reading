require_relative "attribute"

module Reading
  using Util::StringRemove
  using Util::HashArrayDeepFetch

  class Author < Attribute
    def parse
      item_head
        .remove(/\A#{config.deep_fetch(:csv, :regex, :formats)}/)
        .match(/.+(?=#{config.deep_fetch(:csv, :short_separator)})/)
        &.to_s
        &.strip
    end
  end
end
