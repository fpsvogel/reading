module Reading
  class Row
    class SourcesSubattribute
      using Util::StringRemove
      using Util::HashArrayDeepFetch

      private attr_reader :item_head, :bare_variant, :config

      # @param bare_variant [String] the variant string before series / extra info.
      # @param config [Hash]
      def initialize(bare_variant:, config:)
        @bare_variant = bare_variant
        @config = config
      end

      def parse
        urls = sources_urls(bare_variant).map { |url|
          {
            name: url_name(url) || template.deep_fetch(:sources, 0, :name),
            url: url,
          }
        }

        names = sources_names(bare_variant).map { |name|
          {
            name: name,
            url: template.deep_fetch(:sources, 0, :url),
          }
        }

        (urls + names).presence
      end

      private

      def template
        @template ||= config.deep_fetch(:item, :template, :variants).first
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
