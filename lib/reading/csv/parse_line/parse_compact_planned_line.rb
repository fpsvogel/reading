require "active_support/core_ext/object/blank"
require_relative "../../util/deeper_merge"
require_relative "../../errors"
require_relative "parse_line"

module Reading
  module Csv
    class Parse
      using Util::DeeperMerge

      # ParseCompactPlannedLine is a function that parses a line of compactly
      # listed planned items in a CSV reading list into an array of item data (hashes).
      class ParseCompactPlannedLine < ParseLine
        private

        def before_parse(line)
          list_start = line.match(@config.fetch(:csv).fetch(:regex).fetch(:compact_planned_line_start))
          @genre = list_start[:genre].downcase
          @line_without_genre = line.sub(list_start.to_s, "")
        end

        def multi_items_to_be_split_by_format_emojis
          @line_without_genre
        end

        def item_data(name)
          match = name.match(@config.fetch(:csv).fetch(:regex).fetch(:compact_planned_item))
          unless match
            raise InvalidItemError, "Invalid planned item"
          end

          author = ParseAuthor.new(@config).call(match[:author_title])
          title = ParseTitle.new(@config).call(match[:author_title])
          item = template.deeper_merge(
            author: author || template.fetch(:author),
            title: title,
            genres: [@genre] || template.fetch(:genres)
          )

          variants = parse_variants(match)
          item.deeper_merge!(variants: variants)

          item
        end

        def template
          @template ||= @config.fetch(:item).fetch(:template)
        end

        def parse_variants(item_match)
          inverted_variants = sources_with_format_emojis(item_match[:sources])

          variants = []
          inverted_variants[0] ||= {} # because there'll be at least one variant for the first format(s)
          inverted_variants.first[:format_emojis_str] = item_match[:first_format_emojis]

          inverted_variants.each do |inverted_variant|
            inverted_variant[:format_emojis_str] ||= item_match[:first_format_emojis]
            format_emojis = inverted_variant[:format_emojis_str].scan(
              /#{@config.fetch(:csv).fetch(:regex).fetch(:formats)}/
            )
            format_emojis.each do |format_emoji|
              format = format(format_emoji)
              variant_for_format = variants.select { |variant| variant[:format] == format }.first ||
                (variants << blank_variant(format)).last
              variant_for_format[:sources] << inverted_variant[:source] unless inverted_variant[:source].nil?
            end
          end

          variants
        end

        def format(format_emoji)
          @config.fetch(:item).fetch(:formats).key(format_emoji)
        end

        def blank_variant(format)
          {
            format: format,
            sources: [],
            isbn: template.fetch(:variants).first.fetch(:isbn),
            length: template.fetch(:variants).first.fetch(:length),
            extra_info: template.fetch(:variants).first.fetch(:extra_info) }
        end

        def sources_with_format_emojis(sources_str)
          return [] if sources_str.nil?

          sources_str
            .split(@config.fetch(:csv).fetch(:compact_planned_source_prefix))
            .map { |source| source.sub(/\s*,\s*/, "") }
            .map(&:strip)
            .reject(&:empty?)
            .map { |source_str|
              match = source_str.match(@config.fetch(:csv).fetch(:regex).fetch(:compact_planned_source))
              {
                format_emojis_str: match[:format_emojis].presence,
                source: source(match[:source_name])
              }
            }
        end

        def source(source_name)
          if valid_url?(source_name)
            source_name = source_name.chop if source_name.chars.last == "/"
            { name: @config.fetch(:item).fetch(:sources).fetch(:default_name_for_url),
              url: source_name }
          else
            { name: source_name,
              url: nil }
          end
        end

        def valid_url?(str)
          str&.match?(/http[^\s,]+/)
        end
      end
    end
  end
end
