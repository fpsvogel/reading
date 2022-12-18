require_relative "../util/deep_merge"
require_relative "../util/deep_fetch"
require_relative "../errors"
require_relative "row"

module Reading
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

    def item_hash(item_head)
      item_match = item_head.match(config.deep_fetch(:csv, :regex, :compact_planned_item))
      unless item_match
        raise InvalidItemError, "Title missing after #{item_head} in compact planned row"
      end

      author = AuthorAttribute.new(item_head: item_match[:author_title], config:).parse
      title = TitleAttribute.new(item_head: item_match[:author_title], config:).parse

      template.deep_merge(
        author: author || template.fetch(:author),
        title: title,
        genres: [@genre] || template.fetch(:genres),
        variants: [parse_variant(item_match)],
      )
    end

    def template
      @template ||= config.deep_fetch(:item, :template)
    end

    def parse_variant(item_match)
      format_emoji = item_match[:format_emoji]
      {
        format: format(format_emoji),
        sources: sources(item_match[:sources]) || template.deep_fetch(:variants, 0, :sources),
        isbn: template.deep_fetch(:variants, 0, :isbn),
        length: template.deep_fetch(:variants, 0, :length),
        extra_info: template.deep_fetch(:variants, 0, :extra_info),
      }
    end

    def format(format_emoji)
      config.deep_fetch(:item, :formats).key(format_emoji)
    end

    def sources(sources_str)
      return [] if sources_str.nil?

      sources_str
        .split(config.deep_fetch(:csv, :compact_planned_source_prefix))
        .map { |source| source.sub(/\s*,\s*/, "") }
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
