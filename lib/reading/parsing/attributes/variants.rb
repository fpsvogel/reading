module Reading
  module Parsing
    module Attributes
      # Transformer for the :variant item attribute.
      class Variants < Attribute
        using Util::HashArrayDeepFetch
        using Util::NumericToIIfWhole

        # @param parsed_row [Hash] a parsed row (the intermediate hash).
        # @param head_index [Integer] current item's position in the Head column.
        # @return [Array<Hash>] an array of variants; see
        #   Config#default_config[:item][:template][:variants]
        def transform_from_parsed(parsed_row, head_index)
          head = parsed_row[:head][head_index]

          # || [{}] in case there is no Sources column.
          (parsed_row[:sources].presence || [{}])&.map { |variant|
            format = variant[:format] || head[:format]

            {
              format:,
              series: (series(head) + series(variant)).presence,
              sources: sources(variant) || sources(head),
              isbn: variant[:isbn] || variant[:asin],
              length: length(variant, format) || length(parsed_row[:length], format),
              extra_info: Array(head[:extra_info]) + Array(variant[:extra_info]),
            }.map { |k, v| [k, v || template.fetch(k)] }.to_h
          }&.compact&.presence
        end

        # A shortcut to the variant template.
        # @return [Hash]
        def template
          config.deep_fetch(:item, :template, :variants).first
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
        # config[:source_names_from_urls], or nil.
        # @param url [String] a URL.
        # @return [String, nil]
        def url_name(url)
          config
            .fetch(:source_names_from_urls)
            .each do |url_part, name|
              if url.include?(url_part)
                return name
              end
            end

          nil
        end


        def length(hash, format)
          full_length = Attributes::Shared.length(hash, config)
          return nil unless full_length

          speed = config.deep_fetch(:speed, :format)[format] || 1.0

          (full_length / speed).to_i_if_whole
        end
      end
    end
  end
end
