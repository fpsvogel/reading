require "active_support/core_ext/object/blank"
require_relative "../errors"

module Reading
  module Csv
    class Parse
      class ParseLine
        class ParseVariants < ParseAttribute

          def call(name, columns)
            format_in_name = format(name)
            length_in_length = length(columns[:length])
            extra_info_in_name = extra_info(name).presence
            sources_str = columns[:sources]&.presence || " "
            separator =
              if sources_str.match(config.fetch(:csv).fetch(:regex).fetch(:formats))
                config.fetch(:csv).fetch(:regex).fetch(:formats_split)
              else
                config.fetch(:csv).fetch(:long_separator)
              end

            sources_str.split(separator).map { |variant_with_extra_info|
              variant_str = variant_with_extra_info
                .split(config.fetch(:csv).fetch(:long_separator)).first

              variant =
                {
                  format: format(variant_str) || format_in_name || template[:format],
                  sources: sources(variant_str)                 || [],
                  isbn: isbn(variant_str)                       || template[:isbn],
                  length: length(variant_str,
                          in_variant: true) || length_in_length || template[:length],
                  extra_info: extra_info(variant_with_extra_info).presence ||
                                            extra_info_in_name || template[:extra_info]
                }

              if variant != template_with_empty_sources
                variant
              else
                nil
              end
            }.compact.presence || []
          end

          def template
            @template ||= config.fetch(:item).fetch(:template).fetch(:variants).first
          end

          def template_with_empty_sources
            @template_with_empty_sources ||= template.merge(sources: [])
          end

          def format(str)
            emoji = str.match(/^#{config.fetch(:csv).fetch(:regex).fetch(:formats)}/).to_s
            config.fetch(:item).fetch(:formats).key(emoji)
          end

          def isbn(str)
            isbns = str.scan(config.fetch(:csv).fetch(:regex).fetch(:isbn))
            if isbns.count > 1
              raise InvalidItemError, "Only one ISBN/ASIN is allowed per item variant"
            end
            isbns[0]&.to_s
          end

          def length(str, in_variant: false)
            return nil if str.nil?

            len = str.strip
            time_length = len
              .match(config.fetch(:csv).fetch(:regex).fetch(:time_length))&.captures&.first
            return time_length unless time_length.nil?

            pages_length_regex =
              if in_variant
                config.fetch(:csv).fetch(:regex).fetch(:pages_length_in_variant)
              else
                config.fetch(:csv).fetch(:regex).fetch(:pages_length)
              end

            len.match(pages_length_regex)&.captures&.first&.to_i
          end

          def extra_info(str)
            separated = str.split(config.fetch(:csv).fetch(:long_separator))
            separated.delete_at(0) # everything before the extra info
            separated.reject { |str|
              str.start_with?("#{config.fetch(:csv).fetch(:series_prefix)} ") ||
                str.match(config.fetch(:csv).fetch(:regex).fetch(:series_volume))
            }
          end

          def sources(str)
            (sources_urls(str) + sources_names(str).map { |name| [name]})
              .map { |source_array| source_array_to_hash(source_array) }
              .compact.presence
          end

          def sources_urls(str)
            str
              .scan(config.fetch(:csv).fetch(:regex).fetch(:sources))
              .map(&:compact)
              .reject { |source|
                source.first.match?(config.fetch(:csv).fetch(:regex).fetch(:isbn))
              }
          end

          def sources_names(str)
            sources_with_commas_around_length(str)
              .gsub(config.fetch(:csv).fetch(:regex).fetch(:sources), config.fetch(:csv).fetch(:separator))
              .split(config.fetch(:csv).fetch(:separator))
              .reject { |name|
                name.match?(config.fetch(:csv).fetch(:regex).fetch(:time_length)) ||
                  name.match?(config.fetch(:csv).fetch(:regex).fetch(:pages_length_in_variant))
              }
              .map { |name| name.sub(/\A\s*#{config.fetch(:csv).fetch(:regex).fetch(:formats)}\s*/, "") }
              .map(&:strip)
              .reject(&:empty?)
          end

          def sources_with_commas_around_length(str)
            str.sub(config.fetch(:csv).fetch(:regex).fetch(:time_length), ", \\1, ")
               .sub(config.fetch(:csv).fetch(:regex).fetch(:pages_length_in_variant), ", \\1, ")
          end

          def source_array_to_hash(array)
            return nil if array.nil? || array.empty?

            array = [array[0].strip, array[1]&.strip]
            if valid_url?(array[0])
              if valid_url?(array[1])
                raise InvalidItemError, "Each Source must have only one one URL."
              end
              array = array.reverse
            elsif !valid_url?(array[1]) && !array[1].nil?
              raise InvalidItemError, "Invalid URL, or each Source must have only one one name."
            end

            url = array[1]
            url.chop! if url&.chars&.last == "/"
            name = array[0] || auto_name_from_url(url)

            { name: name || template.fetch(:sources).first[:name],
              url: url   || template.fetch(:sources).first[:url] }
          end

          def valid_url?(str)
            str&.match?(/http[^\s,]+/)
          end

          def auto_name_from_url(url)
            return nil if url.nil?

            config
              .fetch(:item).fetch(:sources).fetch(:names_from_urls)
              .each do |url_part, auto_name|
                if url.include?(url_part)
                  return auto_name
                end
              end

            config.fetch(:item).fetch(:sources).fetch(:default_name_for_url)
          end
        end
      end
    end
  end
end