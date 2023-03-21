module Reading
  module Parser
    module Rows
      module CompactPlanned
        class Head < Column
          def self.split_by_format?
            true
          end

          def self.regex_before_formats
            %r{\A
              \\ # comment character
              \s*
              (
                (?<genres>[^a-z]+)?
                \s*
                (?<sources>@.+)?
                \s*:
              )?
            \z}x
          end

          def self.segment_separator
            /\s*--\s*/
          end

          def self.array_keys
            %i[extra_info series_names series_volumes]
          end

          def self.tweaks
            {
              genres: -> { _1.downcase.split(/\s*,\s*/) },
              sources: -> { _1.split(/\s*@/).map(&:presence).compact }
            }
          end

          def self.regexes(segment_index)
            [
              # author, title, sources
              (%r{\A
                (
                  (?<author>[^@]+?)
                  \s+-\s+
                )?
                (?<title>[^@]+)
                (?<sources>@.+)?
              \z}x if  segment_index.zero?),
              *Column::SHARED_REGEXES[:series_and_extra_info],
            ].compact
          end
        end
      end
    end
  end
end
