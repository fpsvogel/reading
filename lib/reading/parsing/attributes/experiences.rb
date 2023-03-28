require "date"
require_relative "experiences/dates_validator"

module Reading
  module Parsing
    module Attributes
      class Experiences < Attribute
        using Util::HashArrayDeepFetch
        using Util::HashDeepMerge

        def extract(parsed_row, head_index)
          head = parsed_row[:head][head_index]
          start_dates_not_empty = parsed_row[:start_dates].presence ||
            [{}] * (parsed_row[:end_dates]&.count || 1)
          start_end_dates = start_dates_not_empty
            .zip(parsed_row[:end_dates] || [])

          experiences_with_dates = start_end_dates.map { |start_entry, end_entry|
            {
              spans: spans(start_entry, end_entry, head, parsed_row),
              group: start_entry[:group],
              variant_index: (start_entry[:variant] || 1).to_i - 1,
            }.map { |k, v| [k, v || template.fetch(k)] }.to_h
          }.presence

          if experiences_with_dates
            # Raises an error if any sequence of dates does not make sense.
            Experiences::DatesValidator.validate(experiences_with_dates, config)
          end

          experiences_with_dates
        end

        private

        def template
          config.deep_fetch(:item_template, :experiences).first
        end

        def spans_template
          config.deep_fetch(:item_template, :experiences, 0, :spans).first
        end

        def progress(hash)
          hash[:progress_time] ||
            hash[:progress_pages]&.to_i ||
            hash[:progress_percent]&.to_i&./(100.0) ||
            (0 if hash[:progress_dnf]) ||
            nil
        end

        def spans(start_entry, end_entry, head, parsed)
          if !start_entry&.dig(:date) && !end_entry&.dig(:date)
            dates = nil
          else
            dates = [start_entry, end_entry].map { |date_hash|
              begin
                Date.parse(date_hash[:date]) if date_hash&.dig(:date)
              rescue Date::Error
                raise InvalidDateError, "Unparsable date \"#{date_hash[:date]}\""
              end
            }
            dates = dates[0]..dates[1]
          end

          variant_index = (start_entry[:variant] || 1).to_i - 1
          length = length(parsed[:sources]&.dig(variant_index)) ||
            length(parsed[:length])

          [
            {
              dates: dates,
              amount: (length if dates),
              progress: progress(start_entry) || progress(head) || (1.0 if end_entry),
              name: spans_template.fetch(:name),
              favorite?: spans_template.fetch(:favorite?),
            }.map { |k, v| [k, v || spans_template.fetch(k)] }.to_h
          ]
        end

        def length(hash)
          hash&.dig(:length_time) ||
            hash&.dig(:length_pages)&.to_i
        end
      end
    end
  end
end
