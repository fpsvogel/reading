require_relative "rows/regular/column"
require_relative "rows/regular/columns/rating"
require_relative "rows/regular/columns/head"
require_relative "rows/regular/columns/sources"
require_relative "rows/regular/columns/dates_started"
require_relative "rows/regular/columns/dates_finished"
require_relative "rows/regular/columns/genres"
require_relative "rows/regular/columns/length"
require_relative "rows/regular/columns/notes"

module Reading
  module Parser
    class Row
      using Util::HashArrayDeepFetch
      using Util::StringRemove

      attr_reader :columns, :config

      def initialize(string, config)
        clean_string = string.dup.force_encoding(Encoding::UTF_8).strip
        column_names = %i[rating head sources dates_started dates_finished genres length notes]
        column_strings = clean_string.split(config.deep_fetch(:csv, :column_separator))
        @columns = column_names.zip(column_strings)

        @config = config
      end

      def parse
        columns.map { |column_name, column_string|
          column = column_class(column_name)

          if column.split_by_format? && column_string.match?(config.deep_fetch(:regex, :formats))
            formats = column_string.split(config.deep_fetch(:regex, :formats_split))

            formats = formats.map { |string|
              format_emoji = string[config.deep_fetch(:regex, :formats)]

              if format_emoji
                string.remove!(format_emoji)
                format = config.deep_fetch(:item, :formats).key(format_emoji)

                [format, parse_segments(column, string)]
              else # a string before the first format
                key, regex = column.regex_before_formats
                parsed = parse_string(string, regex)

                [key, parsed]
              end
            }.to_h

            [column_name, formats]
          else
            [column_name, parse_segments(column, column_string)]
          end
        }.to_h
      end

      private

      def column_class(column_name)
        column_name_camelcase = column_name.to_s.split("_").map(&:capitalize).join
        Columns.const_get(column_name_camelcase)
      end

      def parse_segments(column, string)
        segments = string.split(column.segment_separator).map.with_index { |segment, i|
          regexes = column.regexes(i)

          parsed = nil
          regexes.each do |regex|
            parsed = parse_string(segment, regex)
            break if parsed
          end

          parsed.each do |k, v|
            parsed[k] = [v] if column.array_keys.include?(k) && !v.is_a?(Array)
          end

          parsed
        }

        if column.flatten_segments?
          segments = segments.reduce { |merged, segment|
            merged.merge!(segment) { |k, old_v, new_v|
              # TODO automate this instead of having to specify column#array_keys ??
              old_v = old_v + new_v
            }
          }
        end

        segments
      end

      def parse_string(string, regex)
        string.strip.match(regex)
          &.named_captures
          &.compact
          &.transform_keys(&:to_sym)
          &.transform_values(&:presence)
      end
    end
  end
end
