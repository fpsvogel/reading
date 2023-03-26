module Reading
  module Parsing
    module Rows
      module Regular
        # See https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#head-column-title
        # and https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#head-column-dnf
        # and the sections following.
        class Head < Column
          def self.split_by_format?
            true
          end

          def self.regexes_before_formats
            [
              /\A#{Column::SHARED_REGEXES[:progress]}\z/,
              /.+/,
            ]
          end

          def self.segment_separator
            /\s*--\s*/
          end

          def self.flatten_into_arrays
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
              \z}x if segment_index.zero?),
              *Column::SHARED_REGEXES[:series_and_extra_info],
            ].compact
          end
        end
      end
    end
  end
end
