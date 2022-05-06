module Reading
  module Util
    module DeepFetch
      def dig!(*keys)
        case keys.length
        when 1
          fetch(keys[0])
        when 2
          fetch(keys[0]).fetch(keys[1])
        when 3
          fetch(keys[0]).fetch(keys[1]).fetch(keys[2])
        when 4
          fetch(keys[0]).fetch(keys[1]).fetch(keys[2]).fetch(keys[3])
        end
        # Or this, more flexible but slightly slower.
        # From https://github.com/dogweather/digbang
        # keys.reduce(self) { |a, e| a.fetch(e) }
      end
    end

    module DigBang
      refine Hash do
        include DeepFetch
      end

      refine Array do
        include DeepFetch
      end
    end
  end
end
