require "date"
require_relative "../errors"
require_relative "../util/blank"
require_relative "../util/deep_fetch"

module Reading
  class Row
    class ExperiencesAttribute < Attribute
      using Util::DeepFetch

      def parse
        started, finished = dates_split(columns)

        experiences_with_dates = started.map.with_index { |entry, i|
          {
            date_added: date_added(entry)                 || template.fetch(:date_added),
            spans: spans(entry, finished, i)              || template.fetch(:spans),
            progress: progress(entry) ||
              progress(columns[:head],
                  ignore_if_no_dnf: i < started.count - 1) || template.fetch(:progress),
            group: group(entry)                           || template.fetch(:group),
            variant_index: variant_index(entry)           || template.fetch(:variant_index)
          }
        }.presence

        if experiences_with_dates
          validate_dates_started_are_in_order(experiences_with_dates) if dates_started_column?
          validate_dates_finished_are_in_order(experiences_with_dates) if dates_finished_column?
          validate_experiences_of_same_variant_do_not_overlap(experiences_with_dates) if both_date_columns?
          validate_spans_are_in_order_and_not_overlapping(experiences_with_dates)
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

      def dates_started_column?
        config.deep_fetch(:csv, :columns, :dates_started)
      end

      def dates_finished_column?
        config.deep_fetch(:csv, :columns, :dates_finished)
      end

      def both_date_columns?
        config.deep_fetch(:csv, :columns, :dates_started) && config.deep_fetch(:csv, :columns, :dates_finished)
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

      def date_added(date_entry)
        date_str = date_entry.match(config.deep_fetch(:csv, :regex, :date_added))&.captures&.first
        Date.parse(date_str) if date_str
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
        date_str = date_entry.match(config.deep_fetch(:csv, :regex, :date_started))&.captures&.first
        Date.parse(date_str) if date_str
      end

      def date_finished(dates_finished, date_index)
        return nil if dates_finished.nil?

        date_str = dates_finished[date_index]&.presence
        Date.parse(date_str) if date_str
      end

      def progress(str, ignore_if_no_dnf: false)
        dnf = str.match(config.deep_fetch(:csv, :regex, :dnf))&.captures&.first

        if dnf || !ignore_if_no_dnf
          captures = str.match(config.deep_fetch(:csv, :regex, :progress))&.captures
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
        entry.match(config.deep_fetch(:csv, :regex, :group_experience))&.captures&.first
      end

      def variant_index(date_entry)
        match = date_entry.match(config.deep_fetch(:csv, :regex, :variant_index))

        (match&.captures&.first&.to_i || 1) - 1
      end

      def validate_dates_started_are_in_order(experiences)
        experiences
          .filter { |exp| exp[:spans].any? }
          .map { |exp| exp[:spans].first[:dates].begin }
          .each_cons(2) do |a, b|
            if (a.nil? && b.nil?) || (a && b && a > b )
              raise InvalidDateError, "Dates started are not in order."
            end
          end
      end

      def validate_dates_finished_are_in_order(experiences)
        experiences
          .filter { |exp| exp[:spans].any? }
          .map { |exp| exp[:spans].last[:dates].end }
          .each_cons(2) do |a, b|
            if (a.nil? && b.nil?) || (a && b && a > b )
              raise InvalidDateError, "Dates finished are not in order."
            end
          end
      end

      def validate_experiences_of_same_variant_do_not_overlap(experiences)
        experiences
          .group_by { |exp| exp[:variant_index] }
          .each do |_variant_index, exps|
            exps.filter { |exp| exp[:spans].any? }.each_cons(2) do |a, b|
              a_metaspan = a[:spans].first[:dates].begin..a[:spans].last[:dates].end
              b_metaspan = b[:spans].first[:dates].begin..b[:spans].last[:dates].end
              if a_metaspan.cover?(b_metaspan.begin || a_metaspan.begin || a_metaspan.end) ||
                  b_metaspan.cover?(a_metaspan.begin || b_metaspan.begin || b_metaspan.end)
                raise InvalidDateError, "Experiences are overlapping."
              end
            end
          end
      end

      def validate_spans_are_in_order_and_not_overlapping(experiences)
        experiences
          .filter { |exp| exp[:spans].any? }
          .each do |exp|
            exp[:spans]
              .map { |span| span[:dates] }
              .each do |dates|
                if dates.begin && dates.end && dates.begin > dates.end
                  raise InvalidDateError, "A date range is backward."
                end
              end
              .each_cons(2) do |a, b|
                if a.begin > b.begin || a.end > b.end
                  raise InvalidDateError, "Dates are not in order."
                end
                if a.cover?(b.begin || a.begin || a.end) ||
                    b.cover?(a.begin || b.begin || b.end)
                  raise InvalidDateError, "Dates are overlapping."
                end
              end
          end
      end
    end
  end
end
