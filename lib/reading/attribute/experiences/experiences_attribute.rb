require_relative "date_validator"
require "date"

module Reading
  class Row
    class ExperiencesAttribute < Attribute
      include DateValidator

      using Util::HashArrayDeepFetch

      def parse
        started, finished = dates_split(columns)

        experiences_with_dates = started.map.with_index { |entry, i|
          {
            spans: spans(entry, finished, i)              || template.fetch(:spans),
            progress: progress(entry) ||
              progress(columns[:head],
                  ignore_if_no_dnf: i < started.count - 1) || template.fetch(:progress),
            group: group(entry)                           || template.fetch(:group),
            variant_index: variant_index(entry)           || template.fetch(:variant_index)
          }
        }.presence

        if experiences_with_dates
          DateValidator.validate(experiences_with_dates, config)
          return experiences_with_dates
        else
          if prog = progress(columns[:head])
            return [template.merge(progress: prog)]
          else
            return nil
          end
        end
      end

      private

      def template
        @template ||= config.deep_fetch(:item, :template, :experiences).first
      end

      def dates_split(columns)
        dates_finished = columns[:dates_finished]&.presence
                          &.split(config.deep_fetch(:csv, :separator))&.map(&:strip) || []
        # Don't use #has_key? because simply checking for nil covers the
        # case where dates_started is the last column and omitted.
        started_column_exists = columns[:dates_started]&.presence

        dates_started =
          if started_column_exists
            columns[:dates_started]&.presence&.split(config.deep_fetch(:csv, :separator))&.map(&:strip)
          else
            [""] * dates_finished.count
          end

        [dates_started, dates_finished]
      end

      def spans(date_entry, dates_finished, date_index)
        started = date_started(date_entry)
        finished = date_finished(dates_finished, date_index)
        return [] if started.nil? && finished.nil?

        [{
          dates: started..finished,
          amount: nil,
          description: nil,
        }]
      end

      def date_started(date_entry)
        dates = date_entry.scan(config.deep_fetch(:csv, :regex, :date))
        raise InvalidDateError, "Conjoined dates" if dates.count > 1
        raise InvalidDateError, "Missing or incomplete date" if date_entry.present? && dates.empty?

        date_str = dates.first
        Date.parse(date_str) if date_str
      rescue Date::Error
        raise InvalidDateError, "Unparsable date"
      end

      def date_finished(dates_finished, date_index)
        return nil if dates_finished.nil?

        date_str = dates_finished[date_index]&.presence
        Date.parse(date_str) if date_str
      rescue Date::Error
        if date_str.match?(config.deep_fetch(:csv, :regex, :date))
          raise InvalidDateError, "Unparsable date"
        else
          raise InvalidDateError, "Missing or incomplete date"
        end
      end

      def progress(str, ignore_if_no_dnf: false)
        dnf = str.match(config.deep_fetch(:csv, :regex, :dnf))&.captures&.first

        if dnf || !ignore_if_no_dnf
          match = str.match(config.deep_fetch(:csv, :regex, :progress))
          if match
            if prog_percent = match[:percent]&.to_i
              return prog_percent / 100.0
            elsif prog_time = match[:time]
              return prog_time
            elsif prog_pages = match[:pages]&.to_i
              return prog_pages
            end
          end
        end

        return 0 if dnf
        nil
      end

      def group(entry)
        entry.match(config.deep_fetch(:csv, :regex, :group_experience))&.captures&.first
      end

      def variant_index(date_entry)
        match = date_entry.match(config.deep_fetch(:csv, :regex, :variant_index))

        (match&.captures&.first&.to_i || 1) - 1
      end
    end
  end
end
