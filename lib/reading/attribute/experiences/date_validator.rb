module Reading
  # Methods to validate dates. This does not cover all the ways dates can be
  # invalid, just the ones not covered by ExperiencesAttribute during parsing.
  module DateValidator
    using Util::HashArrayDeepFetch

    class << self
      # Checks the dates in the given experiences hash, and raises an error at
      # the first invalid date found.
      # @param experiences [Array<Hash>]
      # @param config [Hash]
      def validate(experiences, config)
        validate_dates_started_are_in_order(experiences) if dates_started_column?(config)
        validate_dates_finished_are_in_order(experiences) if dates_finished_column?(config)
        validate_experiences_of_same_variant_do_not_overlap(experiences) if both_date_columns?(config)
        validate_spans_are_in_order_and_not_overlapping(experiences)
      end

      private

      def dates_started_column?(config)
        config.deep_fetch(:csv, :columns, :dates_started)
      end

      def dates_finished_column?(config)
        config.deep_fetch(:csv, :columns, :dates_finished)
      end

      def both_date_columns?(config)
        dates_started_column?(config) && dates_finished_column?(config)
      end

      def validate_dates_started_are_in_order(experiences)
        experiences
          .filter { |exp| exp[:spans].any? }
          .map { |exp| exp[:spans].first[:dates].begin }
          .each_cons(2) do |a, b|
            if (a.nil? && b.nil?) || (a && b && a > b )
              raise InvalidDateError, "Dates started are not in order"
            end
          end
      end

      def validate_dates_finished_are_in_order(experiences)
        experiences
          .filter { |exp| exp[:spans].any? }
          .map { |exp| exp[:spans].last[:dates].end }
          .each_cons(2) do |a, b|
            if (a.nil? && b.nil?) || (a && b && a > b )
              raise InvalidDateError, "Dates finished are not in order"
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
                raise InvalidDateError, "Experiences are overlapping"
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
                  raise InvalidDateError, "A date range is backward"
                end
              end
              .each_cons(2) do |a, b|
                if a.begin > b.begin || a.end > b.end
                  raise InvalidDateError, "Dates are not in order"
                end
                if a.cover?(b.begin || a.begin || a.end) ||
                    b.cover?(a.begin || b.begin || b.end)
                  raise InvalidDateError, "Dates are overlapping"
                end
              end
          end
      end
    end
  end
end
