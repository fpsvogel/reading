module Reading
  module Parser
    module Columns
      class Length < Column
        def self.regexes(segment_index)
          [%r{\A
            (
              (?<length_pages>\d+)p?
              |
              (?<length_time>\d+:\d\d)
            )
          \z}x]
        end
      end
    end
  end
end
