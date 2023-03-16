module Reading
  module Parser
    module Columns
      class DatesStarted < Column
        def self.segment_separator
          /,\s*/
        end

        def self.regexes(segment_index)
          # dnf/progress, date, variant number, group
          [%r{\A
            (
              #{SHARED_REGEXES[:progress]}
              \s+
            )?
            (?<date>\d{4}/\d\d?/\d\d?)
            (\s+|\z)
            (
              v(?<variant>\d)
              (\s+|\z)
            )?
            (
              🤝🏼(?<group>.+)
            )?
          \z}x]
        end
      end
    end
  end
end
