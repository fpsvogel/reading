module Reading
  module Util
    # Similar to Array#dig and Hash#dig but raises an error for not found elements.
    module HashArrayDeepFetch
      def deep_fetch(*keys)
        keys.reduce(self) { |a, e| a.fetch(e) }
      end

      refine Hash do
        import_methods HashArrayDeepFetch
      end

      refine Array do
        import_methods HashArrayDeepFetch
      end
    end
  end
end
