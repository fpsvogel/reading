module Reading
  module Parser
    module Rows
      module CompactPlanned
        class Head < Column
          def self.split_by_format?
            true
          end

          def self.tweaks
            {
              genres: -> { _1.downcase.split(/\s*,\s*/) },
              sources: -> { _1.split(/\s*@/).map(&:presence).compact }
            }
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

          def self.regexes(segment_index)
            [%r{\A
              (
                (?<author>[^@]+?)
                \s+-\s+
              )?
              (?<title>[^@]+)
              (?<sources>@.+)?
            \z}x]
          end
        end
      end
    end
  end
end
