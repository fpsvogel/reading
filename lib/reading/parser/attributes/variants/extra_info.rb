module Reading
  module Parser
    module Attributes
      class Variants
        class ExtraInfo
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
              Array(extra_info(item_head)) +
                Array(extra_info(variant_with_extras))
            ).presence
          end

          def parse_head
            extra_info(item_head)
          end

          private

          def template
            config.deep_fetch(:item, :template, :variants, 0, :series).first
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
  end
end
