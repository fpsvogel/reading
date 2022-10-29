module Reading
  module Util
    class FetchDepthExceededError < StandardError
    end

    # Similar to Array#dig and Hash#dig but raises an error for not found elements.
    #
    # More flexible but slightly slower alternative:
    #   keys.reduce(self) { |a, e| a.fetch(e) }
    #
    # See performance comparisons:
    # https://fpsvogel.com/posts/2022/ruby-hash-dot-syntax-deep-fetch
    module DeepFetch
      def deep_fetch(*keys)
        case keys.length
        when 1
          fetch(keys[0])
        when 2
          fetch(keys[0]).fetch(keys[1])
        when 3
          fetch(keys[0]).fetch(keys[1]).fetch(keys[2])
        when 4
          fetch(keys[0]).fetch(keys[1]).fetch(keys[2]).fetch(keys[3])
        else
          raise FetchDepthExceededError, "#deep_fetch can't fetch that deep!"
        end
      end
    end

    module DeepFetch
      refine Hash do
        import_methods DeepFetch
      end

      refine Array do
        import_methods DeepFetch
      end
    end
  end
end
