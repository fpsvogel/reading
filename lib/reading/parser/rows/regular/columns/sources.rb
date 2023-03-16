module Reading
  module Parser
    module Columns
      class Sources < Column
        def self.split_by_format?
          true
        end

        def self.segment_separator
          /\s*--\s*/
        end

        def self.array_keys
          %i[extra_info series_names series_volumes]
        end

        def self.regexes(segment_index)
          [
            # sources, ISBN/ASIN, length
            (%r{\A
              (
                (?<sources>.+?)
                ,?(\s+|\z)
              )?
              (
                (?<isbn>(\d{3}[-\s]?)?[A-Z\d]{10})
                ,?(\s+|\z)
              )?
              (
                (?<length_pages>\d+)p?
                |
                (?<length_time>\d+:\d\d)
              )?
            \z}x if  segment_index.zero?),
            *SHARED_REGEXES[:series_and_extra_info],
          ].compact
        end
      end
    end
  end
end
