module Reading
  module Parsing
    module Attributes
      # Transformer for the :variant item attribute.
      class Variants < Attribute
        using Util::HashArrayDeepFetch

        # @param parsed_row [Hash] a parsed row (the intermediate hash).
        # @param head_index [Integer] current item's position in the Head column.
        # @return [Array<Hash>] an array of variants; see
        #   Config#default_config[:item_template][:variants]
        def transform_from_parsed(parsed_row, head_index)
          head = parsed_row[:head][head_index]

          # || [{}] in case there is no Sources column.
          (parsed_row[:sources].presence || [{}])&.map { |variant|
            {
              format: variant[:format] || head[:format],
              series: (series(head) + series(variant)).presence,
              sources: sources(variant) || sources(head),
              isbn: variant[:isbn],
              length: Attributes::Shared.length(variant) ||
                Attributes::Shared.length(parsed_row[:length]),
              extra_info: Array(head[:extra_info]) + Array(variant[:extra_info]),
            }.map { |k, v| [k, v || template.fetch(k)] }.to_h
          }&.compact&.presence
        end

        # A shortcut to the variant template.
        # @return [Hash]
        def template
          config.deep_fetch(:item_template, :variants).first
        end

        # The :series sub-attribute for the given parsed hash.
        # @param hash [Hash] any parsed hash that contains :series_names and :series_volumes.
        # @return [Array<Hash>]
        def series(hash)
          (hash[:series_names] || [])
            .zip(hash[:series_volumes] || [])
            .map { |name, volume|
              { name:, volume: Integer(volume, exception: false) }
            }
        end

        # The :sources sub-attribute for the given parsed hash.
        # @param hash [Hash] any parsed hash that contains :sources.
        # @return [Array<Hash>]
        def sources(hash)
          hash[:sources]&.map { |source|
            if source.match?(/\Ahttps?:\/\//)
              { name: url_name(source), url: source }
            else
              { name: source, url: nil }
            end
          }
        end

        # The name for the given URL string, according to
        # config[:sources][:names_from_urls] or a default.
        # @param url [String] a URL.
        # @return [String]
        def url_name(url)
          config
            .deep_fetch(:sources, :names_from_urls)
            .each do |url_part, name|
              if url.include?(url_part)
                return name
              end
            end

          nil
        end
      end
    end
  end
end
