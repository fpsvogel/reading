require_relative "series_subattribute"
require_relative "sources_subattribute"

module Reading
  class Row
    class VariantsAttribute < Attribute
      using Util::HashArrayDeepFetch

      def parse
        sources_str = columns[:sources]&.presence || " "

        format_as_separator = config.deep_fetch(:csv, :regex, :formats_split)

        sources_str.split(format_as_separator).map { |variant_with_extras|
          # without extra info or series
          bare_variant = variant_with_extras
            .split(config.deep_fetch(:csv, :long_separator))
            .first

          series = SeriesSubattribute.new(item_head:, variant_with_extras:, config:)
          sources = SourcesSubattribute.new(bare_variant:, config:)

          variant =
            {
              format: format(bare_variant) || format(item_head) || template.fetch(:format),
              series: series.parse                              || template.fetch(:series),
              sources: sources.parse                            || template.fetch(:sources),
              isbn: isbn(bare_variant)                          || template.fetch(:isbn),
              length: length_in_variant_or_length(bare_variant) || template.fetch(:length),
              extra_info: extra_info(variant_with_extras) ||
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
    end
  end
end
