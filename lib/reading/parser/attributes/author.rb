module Reading
  module Parser
    module Attributes
      class Author < Attribute
        using Util::StringRemove
        using Util::HashArrayDeepFetch

        def parse
          item_head
            .remove(/\A#{config.deep_fetch(:csv, :regex, :formats)}/)
            .match(/.+(?=#{config.deep_fetch(:csv, :short_separator)})/)
            &.to_s
            &.strip
        end
      end
    end
  end
end

