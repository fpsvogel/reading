module Reading
  module Parsing
    module Rows
      # The base class for all the columns in parsing/rows/compact_planned_columns
      # and parsing/rows/regular_columns.
      class Column
        # The class name changed into a string, e.g. StartDates => "Start Dates"
        # @return [String]
        def self.column_name
          class_name = name.split("::").last
          class_name.gsub(/(.)([A-Z])/,'\1 \2')
        end

        # The class name changed into a symbol, e.g. StartDates => :start_dates
        # @return [Symbol]
        def self.to_sym
          class_name = name.split("::").last
          class_name
            .gsub(/(.)([A-Z])/,'\1_\2')
            .downcase
            .to_sym
        end

        # Whether the column can contain "chunks" each set off by a format emoji.
        # For example, the Head column of a compact planned row typically
        # contains a list of multiple items. (The two others are the Sources
        # column, for multiple variants of an item; and the regular Head column,
        # for multiple items.)
        # @return [Boolean]
        def self.split_by_format?
          false
        end

        # Whether the column can contain multiple segments, e.g. "Cosmos -- 2013 paperback"
        # @return [Boolean]
        def self.split_by_segment?
          !!segment_separator
        end

        # The regular expression used to split segments (e.g. /\s*--\s*/),
        # or nil if the column should not be split by segment.
        # @return [Regexp, nil]
        def self.segment_separator
          nil
        end

        # Whether the column can contain multiple segment groups, e.g.
        # "2021/1/28..2/1 x4 -- ..2/3 x5 ---- 11/1 -- 11/2"
        # @return [Boolean]
        def self.split_by_segment_group?
          !!segment_group_separator
        end

        # The regular expression used to split segment groups (e.g. /\s*----\s*/),
        # or nil if the column should not be split by segment group.
        # @return [Regexp, nil]
        def self.segment_group_separator
          nil
        end

        # Adjustments that are made to captured values at the end of parsing
        # the column. For example, if ::regexes includes a capture group named
        # "sources" and it needs to be split by commas:
        # { sources: -> { _1.split(/\s*,\s*/) } }
        # @return [Hash{Symbol => Proc}]
        def self.tweaks
          {}
        end

        # Keys in the parsed output hash that should be converted to an array, even
        # if only one value was in the input, as in { ... extra_info: ["ed. Jane Doe"] }
        # @return [Array<Symbol>]
        def self.flatten_into_arrays
          []
        end

        # The regular expressions used to parse the column (except the part of
        # the column before the first format emoji, which is in
        # ::regexes_before_formats below). An array because sometimes it's
        # simpler to try several smaller regular expressions in series, and
        # because a regular expression might be applicable only for segments in
        # a certain position. See parsing/rows/regular_columns/head.rb for an example.
        # @param segment_index [Integer] the position of the current segment.
        # @return [Array<Regexp>]
        def self.regexes(segment_index)
          []
        end

        # The regular expressions used to parse the part of the column before
        # the first format emoji.
        # @return [Array<Regexp>]
        def self.regexes_before_formats
          []
        end

        # Regular expressions that are shared across more than one column,
        # placed here just to be DRY.
        SHARED_REGEXES = {
          progress: %r{
            (DNF\s+)?(?<progress_percent>\d\d?)%
            |
            (DNF\s+)?p?(?<progress_pages>\d+)p?
            |
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
