require_relative "rows/regular"
require_relative "rows/compact_planned"
require_relative "rows/blank"

module Reading
  module Parser
    class Parse
      using Util::HashArrayDeepFetch
      using Util::StringRemove

      attr_reader :config

      def initialize(config)
        @config = config
      end

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

      def extract_columns(string)
        clean_string = string.dup.force_encoding(Encoding::UTF_8)
        column_strings = clean_string.split(config.fetch(:column_separator))

        row_types = [Rows::Regular, Rows::CompactPlanned, Rows::Blank]
        column_classes = row_types
          .find { |row_type| row_type.match?(string, config) }
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

      def parse_column(column_class, column_string)
        if column_class.split_by_format?
          if column_string.match?(config.deep_fetch(:regex, :formats))
            formats = column_string.split(config.deep_fetch(:regex, :formats_split))

            # If there's a string before the first format.
            unless formats.first.match?(config.deep_fetch(:regex, :formats))
              regex = column_class.regex_before_formats
              before_formats = parse_string(formats.shift, regex, column_class.tweaks)
            end

            heads = formats.map { |string|
              format_emoji = string[config.deep_fetch(:regex, :formats)]
              string.remove!(format_emoji)
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

            return [column_class.to_sym, heads]
          else
            parsed_column = parse_segments(column_class, column_string)
            # Wrap a non-empty value in an array so that e.g. a head without
            # emojis is still an array.
            return [column_class.to_sym, [parsed_column.presence].compact]
          end
        else
          return [column_class.to_sym, parse_segments(column_class, column_string)]
        end
      end

      def parse_segments(column_class, string)
        return {} if string.blank?

        if !column_class.split_by_segment?
          return parse_segment(column_class, string)
        end

        segments = string
          .split(column_class.segment_separator)
          .map.with_index { |segment, i|
            parse_segment(column_class, segment, i)
          }

        if column_class.flatten_segments?
          segments = segments.reduce { |merged, segment|
            merged.merge!(segment) { |_k, old_v, new_v|
              # old_v is already an array by this point, since its key should be
              # in Column.array_keys
              old_v + new_v
            }
          }
        end

        segments
      end

      def parse_segment(column_class, string, segment_index = 0)
        regexes = column_class.regexes(segment_index)

        parsed = nil
        regexes.each do |regex|
          parsed = parse_string(string, regex, column_class.tweaks)
          break if parsed
        end

        if parsed.nil?
          raise ParsingError, "Could not parse \"#{string}\" in " \
            "the #{column_class.column_name} column"
        end

        parsed.each do |k, v|
          parsed[k] = [v] if column_class.array_keys.include?(k) && !v.is_a?(Array)
        end

        parsed
      end

      def parse_string(string, regex, tweaks)
        hash = string
          .tr(config.fetch(:ignored_characters), "")
          .strip
          .match(regex)
          &.named_captures
          &.compact
          &.transform_keys(&:to_sym)
          &.transform_values(&:strip)
          &.transform_values(&:presence)

        return nil unless hash

        tweaks.each do |key, tweak|
          if hash.has_key?(key)
            hash[key] = tweak.call(hash[key])
          end
        end

        hash
      end
    end
  end
end