module Reading
  class Row
    class VariantsAttribute < Attribute
      using Util::StringRemove
      using Util::HashArrayDeepFetch

      def parse
        sources_str = columns[:sources]&.presence || " "

        separator =
          if sources_str.match(config.deep_fetch(:csv, :regex, :formats))
            config.deep_fetch(:csv, :regex, :formats_split)
          else
            config.deep_fetch(:csv, :long_separator)
          end

        sources_str.split(separator).map { |variant_with_extra_info|
          variant_str = variant_with_extra_info
            .split(config.deep_fetch(:csv, :long_separator)).first

          variant =
            {
              format: format(variant_str) ||
                        format(item_head)               || template.fetch(:format),
              sources: sources(variant_str)             || template.fetch(:sources),
              isbn: isbn(variant_str)                   || template.fetch(:isbn),
              length: length(variant_str)               || template.fetch(:length),
              extra_info: extra_info(variant_with_extra_info) ||
                            extra_info(item_head)       || template.fetch(:extra_info)
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

      def length(variant_str)
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
        (sources_urls(str) + sources_names(str).map { |name| [name] })
          .map { |source_array| source_array_to_hash(source_array) }
          .compact.presence
      end

      def sources_urls(str)
        str
          .scan(config.deep_fetch(:csv, :regex, :sources))
          .map(&:compact)
          .reject { |source|
            source.first.match?(config.deep_fetch(:csv, :regex, :isbn))
          }
      end

      def sources_names(str)
        sources_with_commas_around_length(str)
          .gsub(config.deep_fetch(:csv, :regex, :sources), config.deep_fetch(:csv, :separator))
          .split(config.deep_fetch(:csv, :separator))
          .reject { |name|
            name.match?(config.deep_fetch(:csv, :regex, :time_length_in_variant)) ||
              name.match?(config.deep_fetch(:csv, :regex, :pages_length_in_variant))
          }
          .map { |name| name.remove(/\A\s*#{config.deep_fetch(:csv, :regex, :formats)}\s*/) }
          .map(&:strip)
          .reject(&:empty?)
      end

      def sources_with_commas_around_length(str)
        str.sub(config.deep_fetch(:csv, :regex, :time_length_in_variant), ", \\1, ")
          .sub(config.deep_fetch(:csv, :regex, :pages_length_in_variant), ", \\1, ")
      end

      def source_array_to_hash(array)
        return nil if array.nil? || array.empty?

        array = [array[0].strip, array[1]&.strip]

        if valid_url?(array[0])
          if valid_url?(array[1])
            raise InvalidSourceError, "Each Source must have only one one URL"
          end
          array = array.reverse
        end

        url = array[1]
        url.chop! if url&.chars&.last == "/"
        name = array[0] || auto_name_from_url(url)

        {
          name: name || template.deep_fetch(:sources, 0, :name),
          url: url   || template.deep_fetch(:sources, 0, :url),
        }
      end

      def valid_url?(str)
        str&.match?(/http[^\s,]+/)
      end

      def auto_name_from_url(url)
        return nil if url.nil?

        config
          .deep_fetch(:item, :sources, :names_from_urls)
          .each do |url_part, auto_name|
            if url.include?(url_part)
              return auto_name
            end
          end

        config.deep_fetch(:item, :sources, :default_name_for_url)
      end
    end
  end
end
