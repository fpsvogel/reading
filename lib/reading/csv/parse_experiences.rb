require "active_support/core_ext/object/blank"
require_relative "../errors"

module Reading
  module Csv
    class Parse
      class ParseLine
        class ParseExperiences < ParseAttribute
          def call(_name = nil, columns)
            started, finished = dates_split(columns)
            if config.fetch(:csv).fetch(:reverse_dates)
              started, finished = started.reverse, finished.reverse
            end
            using_dates = started.map.with_index do |entry, i|
              { date_added: date_added(entry)                 || template[:date_added],
                date_started:  date_started(entry)            || template[:date_started],
                date_finished: date_finished(finished, i)     || template[:date_finished],
                progress: progress(entry) ||
                  progress(columns[:name],
                     ignore_if_no_dnf: i < started.count - 1) || template[:progress],
                group: group(entry)                           || template[:group],
                variant_index: variant_index(entry)                 || template[:variant_index] }
            end.presence
            if using_dates
              return using_dates
            else
              if prog = progress(columns[:name])
                return [template.merge(progress: prog)]
              else
                return []
              end
            end
          end

          def template
            @template ||= config.fetch(:item).fetch(:template).fetch(:experiences).first
          end

          def dates_split(columns)
            dates_finished = columns[:dates_finished]&.presence
                              &.split(config.fetch(:csv).fetch(:separator)) || []
            # Don't use #has_key? because simply checking for nil covers the
            # case where dates_started is the last column and omitted.
            started_column_exists = columns[:dates_started]&.presence
            dates_started =
              if started_column_exists
                columns[:dates_started]&.presence&.split(config.fetch(:csv).fetch(:separator))
              else
                [""] * dates_finished.count
              end
            [dates_started, dates_finished]
          end

          def date_added(date_entry)
            date_entry.match(config.fetch(:csv).fetch(:regex).fetch(:date_added))&.captures&.first
          end

          def date_started(date_entry)
            date_entry.match(config.fetch(:csv).fetch(:regex).fetch(:date_started))&.captures&.first
          end

          def date_finished(dates_finished, date_index)
            return nil if dates_finished.nil?
            dates_finished[date_index]&.strip&.presence
          end

          def progress(str, ignore_if_no_dnf: false)
            dnf = str.match(config.fetch(:csv).fetch(:regex).fetch(:dnf))&.captures&.first
            if dnf || !ignore_if_no_dnf
              captures = str.match(config.fetch(:csv).fetch(:regex).fetch(:progress))&.captures
              if captures
                if prog_percent = captures[1]&.to_i
                  return prog_percent / 100.0
                elsif prog_time = captures[2]
                  return prog_time
                elsif prog_pages = captures[3]&.to_i
                  return prog_pages
                end
              end
            end
            return 0 if dnf
            nil
          end

          def group(entry)
            entry.match(config.fetch(:csv).fetch(:regex).fetch(:group_experience))&.captures&.first
          end

          def variant_index(date_entry)
            match = date_entry.match(config.fetch(:csv).fetch(:regex).fetch(:variant_index))
            (match&.captures&.first&.to_i || 1) - 1
          end
        end
      end
    end
  end
end