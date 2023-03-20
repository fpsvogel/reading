module Reading
  module Parser
    module Rows
      module Regular
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

          def self.tweaks
            {
              sources: -> { _1.split(/\s*,\s*/) },
            }
          end

          def self.regexes(segment_index)
            [
              # ISBN/ASIN and length (without sources)
              (%r{\A
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
end
