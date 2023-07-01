module Reading
  module Parsing
    module Rows
      module Regular
        # See https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#sources-column
        # and https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#sources-column-variants
        class Sources < Column
          SOURCES_PARSING_ERRORS = {
            "The ISBN/ASIN must be placed last in the Sources column" =>
              ->(source) {
                source.match?(/\A#{ISBN_REGEX}/o) || source.match(/\A#{ASIN_REGEX}/o)
              },
          }

          def self.split_by_format?
            true
          end

          def self.segment_separator
            /\s*--\s*/
          end

          def self.flatten_into_arrays
            %i[extra_info series_names series_volumes]
          end

          def self.tweaks
            {
              sources: -> {
                comma = /\s*,\s*/
                space_before_url = / (?=https?:\/\/)/
                sources = _1.split(Regexp.union(comma, space_before_url))

                # Split by space after URL.
                sources = sources.flat_map { |src|
                  if src.match?(/\Ahttps?:\/\//)
                    src.split(" ", 2)
                  else
                    src
                  end
                }

                SOURCES_PARSING_ERRORS.each do |message, check|
                  if sources.any? { |source| check.call(source) }
                    raise ParsingError, message
                  end
                end

                sources
              },
            }
          end

          def self.regexes(segment_index)
            [
              # ISBN/ASIN and length (without sources)
              (%r{\A
                (
                  (?<isbn>(\d{3}[-\s]?)?[A-Z\d]{10})
                  ,?(\s+|\z)
                )?
                (
                  (?<length_pages>\d+)p?
                  |
                  (?<length_time>\d+:\d\d)
                )?
              \z}x if segment_index.zero?),
              # sources, ISBN/ASIN, length
              (%r{\A
                (
                  (?<sources>.+?)
                  ,?(\s+|\z)
                )?
                (
                  (
                    (?<isbn>#{ISBN_REGEX})
                    |
                    (?<asin>#{ASIN_REGEX})
                  )
                  ,?(\s+|\z)
                )?
                (
                  (?<length_pages>\d+)p?
                  |
                  (?<length_time>\d+:\d\d)
                )?
              \z}xo if segment_index.zero?),
              *Column::SHARED_REGEXES[:series_and_extra_info],
            ].compact
          end

          private

          ISBN_REGEX = /(\d{3}[-\s]?)?\d{10}/
          ASIN_REGEX = /B0[A-Z\d]{8}/
        end
      end
    end
  end
end
