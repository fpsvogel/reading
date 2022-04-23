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

        def split_by_format_emojis
          super
          # basic_split = super
          # TODO further process the raw split string. see comments below.
        end

        # TODO allow multiple formats, in either of these two ways:
        # …, 📕🔊Some Title, …
        # …, 📕Some Title @lexpub, 🔊@hoopla, …
        # the limitation is that currently name can't have more than one format
        # emoji because the line is split at format emojis emojis. so, I must
        # further process the raw split string in the overriden
        # split_by_format_emojis above.
        def item_data(name)
          match = name.match(@config.fetch(:csv).fetch(:regex).fetch(:compact_planned_item))
          unless match
            raise InvalidItemError, "Invalid planned item"
          end
          author = ParseAuthor.new(@config).call(match[:author_title])
          title = ParseTitle.new(@config).call(match[:author_title])
          item = template.deeper_merge(
            author: author || template[:author],
            title: title,
            genres: [@genre] || template[:genres]
          )
          variant = {
            format: nil,
            sources: sources(match[:sources]) || template.fetch(:variants).first.fetch(:sources),
            isbn: template.fetch(:variants).first.fetch(:isbn),
            length: template.fetch(:variants).first.fetch(:length),
            extra_info: template.fetch(:variants).first.fetch(:extra_info)
          }
          match[:format_emojis].scan(
            /#{@config.fetch(:csv).fetch(:regex).fetch(:formats)}/
          ).each do |format_emoji|
            item = item.deeper_merge(variants: [variant.merge(format: format(format_emoji))])
          end

          item
        end

        def template
          @template ||= @config.fetch(:item).fetch(:template)
        end

        def format(format_emoji)
          @config.fetch(:item).fetch(:formats).key(format_emoji)
        end

        def sources(sources_str)
          return nil if sources_str.nil?

          sources_str
            .split(@config.fetch(:csv).fetch(:compact_planned_source_prefix))
            .map { |source| source.sub(/\s*,\s*/, "") }
            .map(&:strip)
            .reject(&:empty?)
            .map { |source|
              if valid_url?(source)
                source.chop! if source.chars.last == "/"
                { name: @config.fetch(:item).fetch(:sources).fetch(:default_name_for_url),
                  url: source }
              else
                { name: source,
                  url: template.fetch(:variants).first.fetch(:sources).first[:url] }
              end
            }
            # .reject { |name, url| name.nil? && url.nil? }
        end

        def valid_url?(str)
          str&.match?(/http[^\s,]+/)
        end
      end
    end
  end
end
