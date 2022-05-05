module Reading
  module Util
    # Modified from https://github.com/dogweather/digbang
    def self.deep_fetch(fetchable, keys)
      keys.reduce(fetchable) { |a, e| a.fetch(e) }
    end

    module DigBang
      refine Hash do
        def dig!(*keys)
          Reading::Util.deep_fetch(self, keys)
        end
      end

      refine Array do
        def dig!(*keys)
          Reading::Util.deep_fetch(self, keys)
        end
      end
    end
  end
end
