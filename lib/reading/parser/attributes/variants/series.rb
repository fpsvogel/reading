module Reading
  module Parser
    module Attributes
      class Variants
        class Series
          using Util::HashArrayDeepFetch

          private attr_reader :item_head, :variant_with_extras, :config

          # @param item_head [String] see Row#item_heads for a definition.
          # @param variant_with_extras [String] the full variant string.
          # @param config [Hash]
          def initialize(item_head:, variant_with_extras: nil, config:)
            @item_head = item_head
            @variant_with_extras = variant_with_extras
            @config = config
          end

          def parse
            (
              Array(series(item_head)) +
                Array(series(variant_with_extras))
            ).presence
          end

          def parse_head
            series(item_head)
          end

          private

          def template
            config.deep_fetch(:item, :template, :variants, 0, :series).first
          end

          def series(str)
            separated = str
              .split(config.deep_fetch(:csv, :long_separator))
              .map(&:strip)
              .map(&:presence)
              .compact

            separated.delete_at(0) # everything before the series/extra info

            separated.map { |str|
              volume = str.match(config.deep_fetch(:csv, :regex, :series_volume))
              prefix = "#{config.deep_fetch(:csv, :series_prefix)} "

              if volume || str.start_with?(prefix)
                {
                  name: str.delete_suffix(volume.to_s).delete_prefix(prefix) || template[:name],
                  volume: volume&.captures&.first&.to_i                      || template[:volume],
                }
              end
            }.compact.presence
          end
        end
      end
    end
  end
end
