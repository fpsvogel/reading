require_relative "series_subattribute"
require_relative "sources_subattribute"
require_relative "length_subattribute"

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

          series_attr = SeriesSubattribute.new(item_head:, variant_with_extras:, config:)
          sources_attr = SourcesSubattribute.new(bare_variant:, config:)
          # Length, despite not being very complex, is still split out into a
          # subattribute because it needs to be accessible to
          # ExperiencesAttribute (more specifically SpansSubattribute) which
          # uses length as a default value for amount.
          length_attr = LengthSubattribute.new(bare_variant:, columns:, config:)

          variant =
            {
              format: format(bare_variant) || format(item_head) || template.fetch(:format),
              series: series_attr.parse                         || template.fetch(:series),
              sources: sources_attr.parse                       || template.fetch(:sources),
              isbn: isbn(bare_variant)                          || template.fetch(:isbn),
              length: length_attr.parse                         || template.fetch(:length),
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
