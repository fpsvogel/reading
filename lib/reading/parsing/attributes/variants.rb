module Reading
  module Parsing
    module Attributes
      class Variants < Attribute
        using Util::HashArrayDeepFetch

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
                Attributes::Shared.length(parsed_row[:length], nil_if_each: true),
              extra_info: Array(head[:extra_info]) + Array(variant[:extra_info]),
            }.map { |k, v| [k, v || template.fetch(k)] }.to_h
          }&.compact&.presence
        end

        def template
          config.deep_fetch(:item_template, :variants).first
        end

        def series(hash)
          (hash[:series_names] || [])
            .zip(hash[:series_volumes] || [])
            .map { |name, volume|
              { name:, volume: Integer(volume, exception: false) }
            }
        end

        def sources(hash)
          hash[:sources]&.map { |source|
            if source.match?(/\Ahttps?:\/\//)
              { name: url_name(source), url: source }
            else
              { name: source, url: nil }
            end
          }
        end

        def url_name(url)
          config
            .deep_fetch(:sources, :names_from_urls)
            .each do |url_part, name|
              if url.include?(url_part)
                return name
              end
            end

          config.deep_fetch(:sources, :default_name_for_url)
        end
      end
    end
  end
end
