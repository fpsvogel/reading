require_relative "rows/column"
require_relative "rows/regular"
require_relative "rows/compact_planned"
require_relative "rows/blank"

module Reading
  module Parser
    class Row
      using Util::HashArrayDeepFetch
      using Util::StringRemove

      attr_reader :columns, :config

      def initialize(string, config)
        clean_string = string.dup.force_encoding(Encoding::UTF_8).strip
        column_strings = clean_string.split(config.deep_fetch(:csv, :column_separator))

        row_types = [Rows::Regular, Rows::CompactPlanned, Rows::Blank]
        column_classes = row_types
          .find { |row_type| row_type.match?(string, config) }
          .columns

        @columns = column_classes
          .zip(column_strings)
          .reject { |_class, string| string.nil? }

        @config = config
      end

      def parse
        columns.map { |column, column_string|
          if column.split_by_format? && column_string.match?(config.deep_fetch(:regex, :formats))
            formats = column_string.split(config.deep_fetch(:regex, :formats_split))

            # If there's a string before the first format.
            unless formats.first.match?(config.deep_fetch(:regex, :formats))
              key, regex = column.regex_before_formats
              parsed = parse_string(formats.shift, regex, column.transforms)

              before_formats = { key => parsed }
            end

            formats = formats.map { |string|
              format_emoji = string[config.deep_fetch(:regex, :formats)]
              string.remove!(format_emoji)
              format = config.deep_fetch(:item, :formats).key(format_emoji)

              { format: format, content: parse_segments(column, string) }
            }

            hash = { formats: formats }
            hash = before_formats.merge(hash) if before_formats

            [column.to_sym, hash]
          else
            [column.to_sym, parse_segments(column, column_string)]
          end
        }.to_h
      end

      private

      def parse_segments(column, string)
        if !column.split_by_segment?
          return parse_segment(column, string)
        end

        segments = string.split(column.segment_separator).map.with_index { |segment, i|
          parse_segment(column, segment, i)
        }

        if column.flatten_segments?
          segments = segments.reduce { |merged, segment|
            merged.merge!(segment) { |k, old_v, new_v|
              # old_v is already an array by this point, since its key is part
              # of Column.array_keys
              old_v = old_v + new_v
            }
          }
        end

        segments
      end

      def parse_segment(column, string, segment_index = 0)
        regexes = column.regexes(segment_index)

        parsed = nil
        regexes.each do |regex|
          parsed = parse_string(string, regex, column.transforms)
          break if parsed
        end

        if parsed.nil?
          raise ParsingError, "Could not parse \"#{string}\" in the #{column.column_name} column."
        end

        parsed.each do |k, v|
          parsed[k] = [v] if column.array_keys.include?(k) && !v.is_a?(Array)
        end

        parsed
      end

      def parse_string(string, regex, transforms)
        hash = string.strip.match(regex)
          &.named_captures
          &.compact
          &.transform_keys(&:to_sym)
          &.transform_values(&:strip)
          &.transform_values(&:presence)

        return nil unless hash

        transforms.each do |key, transform|
          if hash.has_key?(key)
            hash[key] = transform.call(hash[key])
          end
        end

        hash
      end
    end
  end
end
