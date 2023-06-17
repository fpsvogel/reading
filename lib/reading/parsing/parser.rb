require_relative 'rows/blank'
require_relative 'rows/regular'
require_relative 'rows/compact_planned'
require_relative 'rows/custom_config'
require_relative 'rows/comment'

module Reading
  module Parsing
    #
    # Parses a string containing a row of a CSV reading log, into a hash
    # mirroring the structure of the row. This hash is an intermediate form and
    # not the final item data. It's the raw material for Parsing::Transformer to
    # generate the final item data.
    #
    # Below is an example intermediate hash parsed from this row, which has a Rating
    # column, then a Head column containing an author, title, series, and extra info:
    #
    # 3|📕Thomas More - Utopia -- trans. Robert Adams -- ed. George Logan -- in Cambridge History of Political Thought
    #
    # {
    #   rating: { number: "1" },
    #   head: [{
    #     author: "Thomas More",
    #     title: "Utopia",
    #     series_names: ["Cambridge History of Political Thought"],
    #     series_volumes: [nil],
    #     extra_info: ["trans. Robert Adams", "ed. George Logan"],
    #     format: :print,
    #   }]
    # }
    #
    # The hash's top-level keys are column names. The nested keys come from
    # regex capture group names in each column (for this example, see ::regexes
    # in rating.rb and head.rb in parsing/rows/regular_columns).
    #
    # All the rest is just details of how the parts of a column are joined:
    #
    # - The :head value is an array because Head.split_by_format? is
    #   true (because a Head column can potentially contain multiple items).
    #   That's also where { format: :print } comes from.
    #
    # - The :series_names and :series_volumes values are arrays because these
    #   keys are in Head.flatten_into_arrays, which causes the column's segments
    #   (separated by " -- ") to be merged into one hash.
    #
    class Parser
      using Util::HashArrayDeepFetch

      attr_reader :config

      # @param config [Hash] an entire config.
      def initialize(config)
        @config = config
      end

      # Parses a row string into a hash that mirrors the structure of the row.
      # @param string [String] a string containing a row of a CSV reading log.
      # @return [Hash]
      def parse_row_to_intermediate_hash(string)
        columns = extract_columns(string)

        if config.fetch(:skip_compact_planned) && columns.has_key?(Rows::CompactPlanned::Head)
          return {}
        end

        columns.map { |column, column_string|
          parse_column(column, column_string)
        }.to_h
      end

      private

      # Splits the row string by column and pairs them in a hash with column
      # classes, which contain the information necessary to parse each column.
      # @param string [String] a string containing a row of a CSV reading log.
      # @return [Hash{Class => String}] a hash whose keys are classes inheriting
      #   Parsing::Rows::Column.
      def extract_columns(string)
        string = string.dup.force_encoding(Encoding::UTF_8)
        column_strings = string.split(config.fetch(:column_separator))

        row_types = [Rows::Blank, Rows::Regular, Rows::CompactPlanned, Rows::CustomConfig, Rows::Comment]
        column_classes = row_types
          .find { |row_type| row_type.match?(string, config) }
          .tap { |row_type|
            if row_type == Rows::CustomConfig
              row_type.merge_custom_config!(string, config)
            end
          }
          .column_classes
          .filter { |column_class|
            config.fetch(:enabled_columns).include?(column_class.to_sym)
          }

        if !column_classes.count.zero? && column_strings.count > column_classes.count
          raise TooManyColumnsError, "Too many columns"
        end

        column_classes
          .zip(column_strings)
          .reject { |_class, string| string.nil? }
          .to_h
      end

      # Parses a column into an array of two elements (a key for the column name
      # and a value of its contents).
      # @param column_class [Class] a class inheriting Parsing::Rows::Column.
      # @param column_string [String] a string containing a column from a row.
      # @return [Array(Symbol, Hash), Array(Symbol, Array)]
      def parse_column(column_class, column_string)
        # Multiple format emojis are possible in some columns:
        # - Head column, for multiple items.
        # - Sources column, for multiple variants of an item.
        # - Compact planned head column, for multiple items.
        # This is the default case below the two guard clauses. It's more complex
        # because there's possibly a string before the first format, and there's
        # an extra level of nesting in the returned array.

        # Simplest case: if the column is never split by format, return the
        # column name and the parsed segment(s), which is either a Hash (if the
        # column can't have multiple segments or if its segments are flattened)
        # or an Array (if there are multiple segments and they're not flattened).
        if !column_class.split_by_format?
          parsed_column = parse_segments(column_class, column_string)
          return [column_class.to_sym, parsed_column]
        end

        # Also simple: if the column *can* be split by format but in this row
        # it doesn't contain any format emojis, return the same as above but
        # with an extra level of nesting (except when the parsed result is nil).
        if column_class.split_by_format? &&
            !column_string.match?(config.deep_fetch(:regex, :formats))

          parsed_column = parse_segments(column_class, column_string)
          # Wrap a non-empty value in an array so that e.g. a head without
          # emojis is still an array. This way the extra level of nesting can
          # be consistently expected for columns that *can* be split by format.
          parsed_column_nonempty_nested = [parsed_column.presence].compact
          return [column_class.to_sym, parsed_column_nonempty_nested]
        end

        # The rest is the complex case: if the column *can and is* split by format.

        # Each format plus the string after it.
        format_strings = column_string.split(config.deep_fetch(:regex, :formats_split))

        # If there's a string before the first format, e.g. "DNF" in Head column.
        unless format_strings.first.match?(config.deep_fetch(:regex, :formats))
          before_formats = parse_segment(column_class, format_strings.shift, before_formats: true)
        end

        # Parse each format-plus-string into an array of segments.
        heads = format_strings.map { |string|
          format_emoji = string[config.deep_fetch(:regex, :formats)]
          string.sub!(format_emoji, '')
          format = config.fetch(:formats).key(format_emoji)

          parse_segments(column_class, string)
            .merge(format: format)
        }

        # Combine values of conflicting keys so that in a compact planned
        # Head column, sources from before_formats are not ignored.
        if before_formats
          heads.each do |head|
            head.merge!(before_formats) do |k, old_v, new_v|
              (new_v + old_v).uniq
            end
          end
        end

        [column_class.to_sym, heads]
      end

      # Parses a string of segments, e.g. "Utopia -- trans. Robert Adams -- ed. George Logan"
      # @param column_class [Class] a class inheriting Parsing::Rows::Column.
      # @param string [String] a string containing segments, which is either an
      #   entire column or (for columns that are split by format emoji) a string
      #   following a format emoji.
      # @return [Array<Hash>, Hash] either an array of parsed segments (hashes),
      #   or a single hash if the column can't be split by segment or if the
      #   segments are flattened into one hash.
      def parse_segments(column_class, string)
        return {} if string.blank?

        # If the column can't be split by segment, parse as a single segment.
        if !column_class.split_by_segment?
          return parse_segment(column_class, string)
        end

        # Add an extra level of nesting if the column can have segment groups,
        # as in "2021/1/28..2/1 x4 -- ..2/3 x5 ---- 11/1 -- 11/2"
        if column_class.split_by_segment_group?
          segments = string
            .split(column_class.segment_group_separator)
            .map { |segment_group|
              segment_group
                .split(column_class.segment_separator)
                .map.with_index { |segment, i|
                  parse_segment(column_class, segment, i)
                }
            }
        else
          segments = string
            .split(column_class.segment_separator)
            .map.with_index { |segment, i|
              parse_segment(column_class, segment, i)
            }
        end

        if column_class.flatten_into_arrays.any?
          segments = segments.reduce { |merged, segment|
            merged.merge!(segment) { |_k, old_v, new_v|
              # old_v is already an array by this point, since its key should be
              # in Column.flatten_into_arrays
              old_v + new_v
            }
          }
        end

        segments
      end

      # Parses a segment using a regular expression from the column class.
      # @param column_class [Class] a class inheriting Parsing::Rows::Column.
      # @param segment [String] a segment, e.g. "Bram Stoker - Dracula".
      # @param segment_index [Integer] the position of the segment when it's in
      #   part of a series of segments; this can change which regular expressions
      #   are applicable to it.
      # @param before_formats [Boolean] whether to use the before-formats regexes.
      # @return [Hash{Symbol => Object}] the parsed segment, whose values are Strings
      #   unless changed via column_class.tweaks or column_class.flatten_into_arrays.
      #   Example: { author: "Bram Stoker", title: "Dracula"}
      def parse_segment(column_class, segment, segment_index = 0, before_formats: false)
        if before_formats
          regexes = column_class.regexes_before_formats
        else
          regexes = column_class.regexes(segment_index)
        end

        parsed_segment = nil
        regexes.each do |regex|
          parsed_segment = parse_segment_with_regex(segment, regex)
          break if parsed_segment
        end

        if parsed_segment.nil?
          raise ParsingError, "Could not parse \"#{segment}\" in " \
            "the #{column_class.column_name} column"
        end

        tweak_and_arrayify_parsed_segment(parsed_segment, column_class)
      end

      # Parses a segment using the given regular expression.
      # @param segment [String] a segment, e.g. "Bram Stoker - Dracula".
      # @param regex [Regexp] the regular expression with which to parse the segment.
      # @return [Hash{Symbol => String}] e.g. { author: "Bram Stoker", title: "Dracula"}
      def parse_segment_with_regex(segment, regex)
        segment
          .tr(config.fetch(:ignored_characters), "")
          .strip
          .match(regex)
          &.named_captures
          &.compact
          &.transform_keys(&:to_sym)
          &.transform_values(&:strip)
          &.transform_values(&:presence)
      end

      # Modify the values of the parsed segment according to column_class.tweaks,
      # and wrap them in an array according to column_class.flatten_into_arrays.
      # @param parsed_segment [Hash] e.g. { author: "Bram Stoker", title: "Dracula"}
      # @return [Hash{Symbol => Object}]
      def tweak_and_arrayify_parsed_segment(parsed_segment, column_class)
        column_class.tweaks.each do |key, tweak|
          if parsed_segment.has_key?(key)
            parsed_segment[key] = tweak.call(parsed_segment[key])
          end
        end

        # Ensure that values of keys in column_class.flatten_into_arrays are arrays.
        column_class.flatten_into_arrays.each do |key|
          if parsed_segment.has_key?(key)
            val = parsed_segment[key]
            # Not using Array(val) because that results in an empty array when
            # val is nil, and the nil must be preserved for series name and
            # volume arrays to line up with an equal number of elements (because
            # the volume may be nil).
            parsed_segment[key] = [val] if !val.is_a?(Array)
          end
        end

        parsed_segment
      end
    end
  end
end
