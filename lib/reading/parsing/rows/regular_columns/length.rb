module Reading
  module Parsing
    module Rows
      module Regular
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
end
