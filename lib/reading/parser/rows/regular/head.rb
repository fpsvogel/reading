module Reading
  module Parser
    module Rows
      module Regular
        class Head < Column
          def self.split_by_format?
            true
          end

          def self.segment_separator
            /\s*--\s*/
          end

          def self.regex_before_formats
            [:progress,
              /\A#{SHARED_REGEXES[:progress]}\z/]
          end

          def self.array_keys
            %i[extra_info series_names series_volumes]
          end

          def self.regexes(segment_index)
            [
              # author and title
              (%r{\A
                (
                  (?<author>.+?)
                  \s+-\s+
                )?
                (?<title>.+)
              \z}x if  segment_index.zero?),
              *SHARED_REGEXES[:series_and_extra_info],
            ].compact
          end
        end
      end
    end
  end
end
