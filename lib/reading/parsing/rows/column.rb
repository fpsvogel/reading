module Reading
  module Parsing
    module Rows
      class Column
        def self.column_name
          class_name = name.split("::").last
          class_name.gsub(/(.)([A-Z])/,'\1 \2')
        end

        def self.to_sym
          class_name = name.split("::").last
          class_name
            .gsub(/(.)([A-Z])/,'\1_\2')
            .downcase
            .to_sym
        end

        def self.split_by_format?
          false
        end

        def self.split_by_segment?
          !!segment_separator
        end

        def self.segment_separator
          nil
        end

        def self.tweaks
          {}
        end

        # Keys in the parsed output hash that should be converted to an array, even
        # if only one value was in the input, e.g. { ... extra_info: ["ed. Jane Doe"] }
        # @return [Array<Symbol>]
        def self.flatten_into_arrays
          []
        end

        def self.regexes(segment_index)
          []
        end

        def self.regexes_before_formats
          []
        end

        SHARED_REGEXES = {
          progress: %r{
            # percent
            (DNF\s+)?(?<progress_percent>\d\d?)%
            |
            # page
            (DNF\s+)?p?(?<progress_pages>\d+)p?
            |
            # time
            (DNF\s+)?(?<progress_time>\d+:\d\d)
            |
            # just DNF
            (?<progress_dnf>DNF)
          }x,
          series_and_extra_info: [
            # just series
            %r{\A
              in\s(?<series_names>.+)
              # empty volume so that names and volumes have equal sizes when turned into arrays
              (?<series_volumes>)
            \z}x,
            # series and volume
            %r{\A
              (?<series_names>.+?)
              ,?\s*
              \#(?<series_volumes>\d+)
            \z}x,
            # extra info
            %r{\A
              (?<extra_info>.+)
            \z}x,
          ],
        }.freeze
      end
    end
  end
end
