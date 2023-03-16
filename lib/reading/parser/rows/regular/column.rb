module Reading
  module Parser
    class Column
      def self.split_by_format?
        false
      end

      def self.segment_separator
        nil
      end

      def self.array_keys
        []
      end

      def self.flatten_segments?
        array_keys.any?
      end

      def self.regexes(segment_index)
        []
      end

      SHARED_REGEXES = {
        progress: %r{
          # DNF percent
          (DNF\s+)?(?<progress_percent>\d\d?)%
          |
          # DNF page
          (DNF\s+)?p(?<progress_page>\d+)
          |
          # DNF time
          (DNF\s+)?(?<progress_time>\d+:\d\d)
          |
          # just DNF
          DNF
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
