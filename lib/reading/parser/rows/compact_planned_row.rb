require_relative "row"
require_relative "../attributes/attribute"
require_relative "../attributes/author"
require_relative "../attributes/title"
require_relative "../attributes/variants"

module Reading
  module Parser
    module Rows
      # Parses a row of compactly listed planned items into an array of hashes of
      # item data.
      class CompactPlannedRow < Row
        using Util::StringRemove
        using Util::HashDeepMerge
        using Util::HashArrayDeepFetch

        # Whether the given CSV line is a compact planned row.
        # @param line [Reading::Line]
        # @return [Boolean]
        def self.match?(line)
          comment_char = line.csv.config.deep_fetch(:csv, :comment_character)

          line.string.strip.start_with?(comment_char) &&
            line.string.match?(line.csv.config.deep_fetch(:csv, :regex, :compact_planned_row_start))
        end

        private

        def skip?
          config.deep_fetch(:csv, :skip_compact_planned)
        end

        def before_parse
          to_ignore = config.deep_fetch(:csv, :regex, :compact_planned_ignored_chars)
          start_regex = config.deep_fetch(:csv, :regex, :compact_planned_row_start)

          string_without_ignored_chars = string.remove_all(to_ignore)
          start = string_without_ignored_chars.match(start_regex)

          @genres = Array(start[:genres]&.downcase&.strip&.split(",")&.map(&:strip))
          @sources = sources(start[:sources])
          @row_without_genre = string_without_ignored_chars.remove(start.to_s)
        end

        def string_to_be_split_by_format_emojis
          @row_without_genre
        end

        def item_hash(item_head)
          item_match = item_head.match(config.deep_fetch(:csv, :regex, :compact_planned_item))
          unless item_match
            raise InvalidHeadError, "Title missing after #{item_head} in compact planned row"
          end

          author = Attributes::Author.new(
            item_head: item_match[:author_title],
            config:,
          ).parse

          begin
            title = Attributes::Title.new(
              item_head: item_match[:author_title],
              config:,
            ).parse
          rescue InvalidHeadError
            raise InvalidHeadError, "Title missing after #{item_head} in compact planned row"
          end

          if item_match[:sources_column]
            if item_match[:sources_column].include?(config.deep_fetch(:csv, :column_separator))
              raise TooManyColumnsError, "Too many columns (only Sources allowed) " \
                "after #{item_head} in compact planned row"
            end

            variants_attr = Attributes::Variants.new(
              item_head: item_match[:format_emoji] + item_match[:author_title],
              columns: { sources: item_match[:sources_column], length: nil },
              config:,
            )
            variants = variants_attr.parse
          else
            variants = [parse_variant(item_match)]
          end

          template.deep_merge(
            author: author || template.fetch(:author),
            title: title,
            genres: @genres.presence || template.fetch(:genres),
            variants:,
          )
        end

        def template
          @template ||= config.deep_fetch(:item, :template)
        end

        def parse_variant(item_match)
          item_head = item_match[:format_emoji] + item_match[:author_title]
          series_attr = Attributes::Variants::Series.new(item_head:, config:)
          extra_info_attr = Attributes::Variants::ExtraInfo.new(item_head:, config:)
          sources = (@sources + sources(item_match[:sources])).uniq.presence

          {
            format: format(item_match[:format_emoji]),
            series: series_attr.parse_head          || template.deep_fetch(:variants, 0, :series),
            sources: sources                        || template.deep_fetch(:variants, 0, :sources),
            isbn:                                   template.deep_fetch(:variants, 0, :isbn),
            length:                                 template.deep_fetch(:variants, 0, :length),
            extra_info: extra_info_attr.parse_head  || template.deep_fetch(:variants, 0, :extra_info),
          }
        end

        def format(format_emoji)
          config.deep_fetch(:item, :formats).key(format_emoji)
        end

        def sources(sources_str)
          return [] if sources_str.nil?

          sources_str
            .split(config.deep_fetch(:csv, :compact_planned_source_prefix))
            .map { |source| source.remove(/\s*,\s*/) }
            .map(&:strip)
            .reject(&:empty?)
            .map { |source_name|
              if valid_url?(source_name)
                source_name = source_name.chop if source_name.chars.last == "/"
                { name: config.deep_fetch(:item, :sources, :default_name_for_url),
                  url: source_name }
              else
                { name: source_name,
                  url: nil }
              end
            }
        end

        def valid_url?(str)
          str&.match?(/http[^\s,]+/)
        end
      end
    end
  end
end
