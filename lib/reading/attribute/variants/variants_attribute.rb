require_relative "series_subattribute"

module Reading
  class Row
    class VariantsAttribute < Attribute
      using Util::StringRemove
      using Util::HashArrayDeepFetch

      def parse
        sources_str = columns[:sources]&.presence || " "

        format_as_separator = config.deep_fetch(:csv, :regex, :formats_split)

        sources_str.split(format_as_separator).map { |variant_with_extra_info|
          bare_variant = variant_with_extra_info
            .split(config.deep_fetch(:csv, :long_separator))
            .first

          series = SeriesSubattribute.new(item_head:, variant_with_extra_info:, config:)

          variant =
            {
              format: format(bare_variant) || format(item_head) || template.fetch(:format),
              series: series.parse                              || template.fetch(:series),
              sources: sources(bare_variant)                    || template.fetch(:sources),
              isbn: isbn(bare_variant)                          || template.fetch(:isbn),
              length: length_in_variant_or_length(bare_variant) || template.fetch(:length),
              extra_info: extra_info(variant_with_extra_info) ||
                                          extra_info(item_head) || template.fetch(:extra_info)
            }

          if variant != template
            variant
          else
            nil
          end
        }.compact.presence
      end

      private

      def template
        @template ||= config.deep_fetch(:item, :template, :variants).first
      end

      def format(str)
        emoji = str.match(/^#{config.deep_fetch(:csv, :regex, :formats)}/).to_s
        config.deep_fetch(:item, :formats).key(emoji)
      end

      def isbn(str)
        isbns = str.scan(config.deep_fetch(:csv, :regex, :isbn))
        if isbns.count > 1
          raise InvalidSourceError, "Only one ISBN/ASIN is allowed per item variant"
        end
        isbns[0]&.to_s
      end

      def length_in(str, time_regex:, pages_regex:)
        return nil if str.blank?

        time_length = str.strip.match(time_regex)&.captures&.first
        return time_length unless time_length.nil?

        str.strip.match(pages_regex)&.captures&.first&.to_i
      end

      def length_in_variant_or_length(variant_str)
        in_variant = length_in(
          variant_str,
          time_regex: config.deep_fetch(:csv, :regex, :time_length_in_variant),
          pages_regex: config.deep_fetch(:csv, :regex, :pages_length_in_variant),
        )
        in_length = length_in(
          columns[:length],
          time_regex: config.deep_fetch(:csv, :regex, :time_length),
          pages_regex: config.deep_fetch(:csv, :regex, :pages_length),
        )

        in_variant || in_length ||
          (raise InvalidLengthError, "Missing length" unless columns[:length].blank?)
      end

      def extra_info(str)
        separated = str.split(config.deep_fetch(:csv, :long_separator))
        separated.delete_at(0) # everything before the extra info
        separated.reject { |str|
          str.start_with?("#{config.deep_fetch(:csv, :series_prefix)} ") ||
            str.match(config.deep_fetch(:csv, :regex, :series_volume))
        }.presence
      end

      def sources(str)
        urls = sources_urls(str).map { |url|
          {
            name: url_name(url) || template.deep_fetch(:sources, 0, :name),
            url: url,
          }
        }

        names = sources_names(str).map { |name|
          {
            name: name,
            url: template.deep_fetch(:sources, 0, :url),
          }
        }

        (urls + names).presence
      end

      def sources_urls(str)
        str.scan(config.deep_fetch(:csv, :regex, :url))
      end

      # Turns everything that is not a source name (ISBN, source URL, length) into
      # a separator, then splits by that separator and removes empty elements
      # and format emojis. What's left is source names.
      def sources_names(str)
        not_names = [:isbn, :url, :time_length_in_variant, :pages_length_in_variant]
        names_and_separators = str

        not_names.each do |regex_type|
          names_and_separators = names_and_separators.gsub(
            config.deep_fetch(:csv, :regex, regex_type),
            config.deep_fetch(:csv, :separator),
          )
        end

        names_and_separators
          .split(config.deep_fetch(:csv, :separator))
          .map { |name| name.remove(/\A\s*#{config.deep_fetch(:csv, :regex, :formats)}\s*/) }
          .map(&:strip)
          .reject(&:empty?)
      end

      def url_name(url)
        config
          .deep_fetch(:item, :sources, :names_from_urls)
          .each do |url_part, name|
            if url.include?(url_part)
              return name
            end
          end

        config.deep_fetch(:item, :sources, :default_name_for_url)
      end
    end
  end
end
