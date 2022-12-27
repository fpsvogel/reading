module Reading
  class Row
    class SeriesSubattribute
      using Util::HashArrayDeepFetch

      private attr_reader :item_head, :variant_with_extras, :config

      # @param item_head [String] see Row#item_heads for a definition.
      # @param variant_with_extras [String] the full variant string.
      # @param config [Hash]
      def initialize(item_head:, variant_with_extras:, config:)
        @item_head = item_head
        @variant_with_extras = variant_with_extras
        @config = config
      end

      def parse
        separated = [item_head, variant_with_extras].map { |str|
          str.split(config.deep_fetch(:csv, :long_separator))
            .map(&:strip)
            .map(&:presence)
            .compact
        }

        separated.each do |str|
          str.delete_at(0) # everything before the series/extra info
        end

        separated.flatten!

        separated.map { |str|
          volume = str.match(config.deep_fetch(:csv, :regex, :series_volume))
          prefix = "#{config.deep_fetch(:csv, :series_prefix)} "

          if volume || str.start_with?(prefix)
            {
              name: str.delete_suffix(volume.to_s).delete_prefix(prefix) || default[:name],
              volume: volume&.captures&.first&.to_i                      || default[:volume],
            }
          end
        }.compact.presence
      end

      private

      def default
        config.deep_fetch(:item, :template, :variants, 0, :series).first
      end
    end
  end
end
