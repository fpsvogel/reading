module Reading
  module Parser
    module Attributes
      class Variants < Attribute
        class Length
          using Util::HashArrayDeepFetch

          private attr_reader :item_head, :bare_variant, :columns, :config

          # @param bare_variant [String] the variant string before series / extra info.
          # @param columns [Array<String>]
          # @param config [Hash]
          def initialize(bare_variant:, columns:, config:)
            @bare_variant = bare_variant
            @columns = columns
            @config = config
          end

          def parse
            in_variant = length_in(
              bare_variant,
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

          private

          def length_in(str, time_regex:, pages_regex:)
            return nil if str.blank?

            time_length = str.strip.match(time_regex)&.captures&.first
            return time_length unless time_length.nil?

            str.strip.match(pages_regex)&.captures&.first&.to_i
          end
        end
      end
    end
  end
end
