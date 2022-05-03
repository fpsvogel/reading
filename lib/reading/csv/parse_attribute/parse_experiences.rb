require "active_support/core_ext/object/blank"
require_relative "../../errors"

# GOATSONG example in @files[:examples][:in_progress]
# [{ dates: Date.parse("2019-05-01"), amount: 31 },
#   { dates: Date.parse("2019-05-02"), amount: 23 },
#   { dates: Date.parse("2019-05-06")..Date.parse("2019-05-15"), amount: 10 },
#   { dates: Date.parse("2019-05-20"), amount: 46 },
#   { dates: Date.parse("2019-05-21"), amount: 47 }]

# 5|50% 📕Tom Holt - Goatsong: A Novel of Ancient Athens -- The Walled Orchard, #1|0312038380|2019/05/28, 2020/05/01, 2021/08/17|2019/06/13, 2020/05/23|historical fiction|247||||2019/5/1 p31 -- 5/2 p54 -- 5/6-15 10p -- 5/20 p200 -- 5/21 done

module Reading
  module Csv
    class Parse
      class ParseLine
        class ParseExperiences < ParseAttribute

          def call(_name = nil, columns)
            started, finished = dates_split(columns)
            if @config.fetch(:csv).fetch(:reverse_dates)
              started, finished = started.reverse, finished.reverse
            end

            using_dates = started.map.with_index { |entry, i|
              {
                date_added: date_added(entry)                 || template.fetch(:date_added),
                spans: spans(entry, finished, i)              || template.fetch(:spans),
                # date_started:  date_started(entry)            || template.fetch(:date_started),
                # date_finished: date_finished(finished, i)     || template.fetch(:date_finished),
                progress: progress(entry) ||
                  progress(columns[:name],
                     ignore_if_no_dnf: i < started.count - 1) || template.fetch(:progress),
                group: group(entry)                           || template.fetch(:group),
                variant_index: variant_index(entry)           || template.fetch(:variant_index)
              }
            }.presence

            if using_dates
              return using_dates
            else
              if prog = progress(columns[:name])
                return [template.merge(progress: prog)]
              else
                return nil
              end
            end
          end

          def template
            @template ||= @config.fetch(:item).fetch(:template).fetch(:experiences).first
          end

          def dates_split(columns)
            dates_finished = columns[:dates_finished]&.presence
                              &.split(@config.fetch(:csv).fetch(:separator)) || []
            # Don't use #has_key? because simply checking for nil covers the
            # case where dates_started is the last column and omitted.
            started_column_exists = columns[:dates_started]&.presence
            dates_started =
              if started_column_exists
                columns[:dates_started]&.presence&.split(@config.fetch(:csv).fetch(:separator))
              else
                [""] * dates_finished.count
              end
            [dates_started, dates_finished]
          end

          def date_added(date_entry)
            date_entry.match(@config.fetch(:csv).fetch(:regex).fetch(:date_added))&.captures&.first
          end

          def spans(date_entry, dates_finished, date_index)
            started = date_started(date_entry)
            finished = date_finished(dates_finished, date_index)
            return [] if started.nil? && finished.nil?

            [{
              dates: started..finished,
              amount: nil,
              description: nil
            }]
          end

          def date_started(date_entry)
            date_entry.match(@config.fetch(:csv).fetch(:regex).fetch(:date_started))&.captures&.first
          end

          def date_finished(dates_finished, date_index)
            return nil if dates_finished.nil?
            dates_finished[date_index]&.strip&.presence
          end

          def progress(str, ignore_if_no_dnf: false)
            dnf = str.match(@config.fetch(:csv).fetch(:regex).fetch(:dnf))&.captures&.first

            if dnf || !ignore_if_no_dnf
              captures = str.match(@config.fetch(:csv).fetch(:regex).fetch(:progress))&.captures
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
            entry.match(@config.fetch(:csv).fetch(:regex).fetch(:group_experience))&.captures&.first
          end

          def variant_index(date_entry)
            match = date_entry.match(@config.fetch(:csv).fetch(:regex).fetch(:variant_index))
            (match&.captures&.first&.to_i || 1) - 1
          end
        end
      end
    end
  end
end