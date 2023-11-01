module Reading
  module Parsing
    module Attributes
      class Experiences < Attribute
        # Methods to validate dates in spans. This does not cover all the ways
        # dates can be invalid, just the ones not caught during parsing.
        module SpansValidator
          using Util::HashArrayDeepFetch

          class << self
            # Checks the dates in the given experiences hash, and raises an error
            # at the first invalid date found.
            # @param experiences [Array<Hash>] experience hashes.
            # @param history_column [Boolean] whether this validation is for
            #   experiences from the History column.
            # @raise [InvalidDateError] if any date is invalid.
            def validate(experiences, history_column: false)
              if both_date_columns? && !history_column
                validate_number_of_start_dates_and_end_dates(experiences)
              end

              if start_dates_column? || history_column
                validate_start_dates_are_in_order(experiences)
              end

              if end_dates_column? || history_column
                validate_end_dates_are_in_order(experiences)
              end

              if both_date_columns? || history_column
                validate_experiences_of_same_variant_do_not_overlap(experiences)
              end

              validate_spans_are_in_order_and_not_overlapping(experiences)
            end

            private

            # Whether the Start Dates column is enabled.
            # @return [Boolean]
            def start_dates_column?
              Config.hash.fetch(:enabled_columns).include?(:start_dates)
            end

            # Whether the End Dates column is enabled.
            # @return [Boolean]
            def end_dates_column?
              Config.hash.fetch(:enabled_columns).include?(:end_dates)
            end

            # Whether both the Start Dates and End Dates columns are enabled.
            # @return [Boolean]
            def both_date_columns?
              start_dates_column? && end_dates_column?
            end

            # Raises an error if there are more end dates than start dates, or
            # if there is more than one more start date than end dates.
            # @raise [InvalidDateError]
            def validate_number_of_start_dates_and_end_dates(experiences)
              _both_dates, not_both_dates = experiences
                .select { |exp| exp[:spans].first&.dig(:dates) }
                .map { |exp| [exp[:spans].first[:dates].begin, exp[:spans].last[:dates].end] }
                .partition { |start_date, end_date| start_date && end_date }

              all_dates_paired = not_both_dates.empty?
              last_date_started_present = not_both_dates.count == 1 && not_both_dates.first

              unless all_dates_paired || last_date_started_present
                raise InvalidDateError, "Start dates or end dates are missing"
              end
            end

            # Raises an error if the spans' first start dates are not in order.
            # @raise [InvalidDateError]
            def validate_start_dates_are_in_order(experiences)
              experiences
                .select { |exp| exp[:spans].first&.dig(:dates) }
                .map { |exp| exp[:spans].first[:dates].begin }
                .each_cons(2) do |a, b|
                  if (a.nil? && b.nil?) || (a && b && a > b )
                    raise InvalidDateError, "Start dates are not in order"
                  end
                end
            end

            # Raises an error if the spans' last end dates are not in order.
            # @raise [InvalidDateError]
            def validate_end_dates_are_in_order(experiences)
              experiences
                .select { |exp| exp[:spans].first&.dig(:dates) }
                .map { |exp| exp[:spans].last[:dates]&.end }
                .each_cons(2) do |a, b|
                  if (a.nil? && b.nil?) || (a && b && a > b )
                    raise InvalidDateError, "End dates are not in order"
                  end
                end
            end

            # Raises an error if two experiences of the same variant overlap.
            # @raise [InvalidDateError]
            def validate_experiences_of_same_variant_do_not_overlap(experiences)
              experiences
                .group_by { |exp| exp[:variant_index] }
                .each do |_variant_index, exps|
                  exps.select { |exp| exp[:spans].any? }.each_cons(2) do |a, b|
                    a_metaspan = a[:spans].first[:dates].begin..a[:spans].last[:dates].end
                    b_metaspan = b[:spans].first[:dates].begin..b[:spans].last[:dates].end
                    if a_metaspan.cover?(b_metaspan.begin || a_metaspan.begin || a_metaspan.end) ||
                        b_metaspan.cover?(a_metaspan.begin || b_metaspan.begin || b_metaspan.end)
                      raise InvalidDateError, "Experiences are overlapping"
                    end
                  end
                end
            end

            # Raises an error if the spans within an experience are out of order
            # or if the spans overlap. Spans with nil dates are not considered.
            # @raise [InvalidDateError]
            def validate_spans_are_in_order_and_not_overlapping(experiences)
              experiences
                .select { |exp| exp[:spans].first&.dig(:dates) }
                .each do |exp|
                  exp[:spans]
                    .map { |span| span[:dates] }
                    # Exclude nil dates (planned entries in History).
                    .reject { |dates| dates.nil? }
                    .each do |dates|
                      if dates.begin && dates.end && dates.begin > dates.end
                        raise InvalidDateError, "A date range is backward"
                      end
                    end
                    .each_cons(2) do |a, b|
                      if a.begin > b.begin || (a.end || Date.today) > (b.end || Date.today)
                        raise InvalidDateError, "Dates are not in order"
                      end
                      if a.cover?(b.begin + 1)
                        raise InvalidDateError, "Dates are overlapping"
                      end
                    end
                end
            end
          end
        end
      end
    end
  end
end
