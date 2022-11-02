require_relative "../../util/blank"
require_relative "../../util/deep_merge"
require_relative "../../util/deep_fetch"
require_relative "../../errors"
require_relative "row"

module Reading
  class CSV
    # Parses a row of compactly listed planned items into an array of hashes of
    # item data.
    class CompactPlannedRow < Row
      using Util::DeepMerge
      using Util::DeepFetch

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
        list_start = string.match(config.deep_fetch(:csv, :regex, :compact_planned_row_start))
        @genre = list_start[:genre].downcase
        @row_without_genre = string.sub(list_start.to_s, "")
      end

      def string_to_be_split_by_format_emojis
        @row_without_genre
      end

      def item_hash(head)
        match = head.match(config.deep_fetch(:csv, :regex, :compact_planned_item))
        unless match
          raise InvalidItemError, "Invalid planned item"
        end

        author = ParseAuthor.new(config).call(match[:author_title])
        title = ParseTitle.new(config).call(match[:author_title])
        item = template.deep_merge(
          author: author || template.fetch(:author),
          title: title,
          genres: [@genre] || template.fetch(:genres)
        )

        variants = parse_variants(match)
        item.deep_merge!(variants: variants)

        item
      end

      def template
        @template ||= config.deep_fetch(:item, :template)
      end

      def parse_variants(item_match)
        inverted_variants = sources_with_format_emojis(item_match[:sources])

        variants = []
        inverted_variants[0] ||= {} # because there'll be at least one variant for the first format(s)
        inverted_variants.first[:format_emojis_str] = item_match[:first_format_emojis]

        inverted_variants.each do |inverted_variant|
          inverted_variant[:format_emojis_str] ||= item_match[:first_format_emojis]
          format_emojis = inverted_variant[:format_emojis_str].scan(
            /#{config.deep_fetch(:csv, :regex, :formats)}/
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
        config.deep_fetch(:item, :formats).key(format_emoji)
      end

      def blank_variant(format)
        {
          format: format,
          sources: [],
          isbn: template.deep_fetch(:variants, 0, :isbn),
          length: template.deep_fetch(:variants, 0, :length),
          extra_info: template.deep_fetch(:variants, 0, :extra_info) }
      end

      def sources_with_format_emojis(sources_str)
        return [] if sources_str.nil?

        sources_str
          .split(config.deep_fetch(:csv, :compact_planned_source_prefix))
          .map { |source| source.sub(/\s*,\s*/, "") }
          .map(&:strip)
          .reject(&:empty?)
          .map { |source_str|
            match = source_str.match(config.deep_fetch(:csv, :regex, :compact_planned_source))
            {
              format_emojis_str: match[:format_emojis].presence,
              source: source(match[:source_name])
            }
          }
      end

      def source(source_name)
        if valid_url?(source_name)
          source_name = source_name.chop if source_name.chars.last == "/"
          { name: config.deep_fetch(:item, :sources, :default_name_for_url),
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
