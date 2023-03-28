module Reading
  module Parsing
    module Rows
      module Regular
        # See https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#history-column
        class History < Column
          def self.segment_separator
            /\s*--\s*/
          end

          def self.segment_group_separator
            /\s*----\s*/
          end

          def self.tweaks
            {
              not_dates: ->(dates_list) {
                dates_list
                  .split(/\s*,\s*/)
                  .map { |date|
                    date.match(
                      %r{\A
                        #{START_END_DATES_REGEX}
                      \z}xo
                    )
                    &.named_captures
                    &.compact
                    &.transform_keys(&:to_sym)
                    &.presence
                  }
                  .compact
              },
            }
          end

          def self.regexes(segment_index)
            [
              # entry of "except these dates"
              %r{\A
                not
                \s+
                (?<not_dates>.+)
              \z}x,
              # normal entry
              %r{\A
                \(?\s*
                # variant, group before first start date
                (
                  (
                    v(?<variant>\d)
                    (\s+|\z)
                  )?
                  (
                    🤝🏼(?<group>.+?)
                  )?
                  (?=(\d{4}/)?\d\d?/\d\d?)
                )?
                # planned or dates
                (
                  (
                    (?<planned>\?)
                    |
                    (#{START_END_DATES_REGEX})
                  )
                  (\s*\)?\s*\z|\s+)
                )?
                # progress
                (
                  # requires the at symbol, unlike the shared progress regex in Column
                  # and also adds the done option
                  (
                    (DNF\s+)?@?(?<progress_percent>\d\d?)%
                    |
                    (DNF\s+)?@p?(?<progress_pages>\d+)p?
                    |
                    (DNF\s+)?@(?<progress_time>\d+:\d\d)
                    |
                    # just DNF
                    (?<progress_dnf>DNF)
                    |
                    # done
                    (?<progress_done>done)
                  )
                  (\s*\)?\s*\z|\s+)
                )?
                # amount
                (
                  (
                    p?(?<amount_pages>\d+)p?
                    |
                    (?<amount_time>\d+:\d\d)
                  )
                  (\s*\)?\s*\z|\s+)
                )?
                # repetitions
                (
                  (
                    x(?<repetitions>\d+)
                    (/(?<frequency>day|week|month))?
                  )
                  (\s*\)?\s*\z|\s+)
                )?
                # favorite, name
                (
                  (?<favorite>⭐)?
                  \s*
                  (?<name>[^\d].*)
                )?
              \z}xo,
            ]
          end

          private

          START_END_DATES_REGEX =
            %r{
              (
                (?<start_year>\d{4})
                /
              )?
              (
                (?<start_month>\d\d?)
                /
              )?
              (?<start_day>\d\d?)?
              (?<range>\.\.)?
              (
                (?<=\.\.)
                (
                  (?<end_year>\d{4})
                  /
                )?
                (
                  (?<end_month>\d\d?)
                  /
                )?
                (?<end_day>\d\d?)?
              )?
            }x
        end
      end
    end
  end
end
