require "date"
require_relative "experiences/dates_validator"

module Reading
  module Parsing
    module Attributes
      class Experiences
        using Util::HashArrayDeepFetch
        using Util::HashDeepMerge

        private attr_reader :config

        def initialize(config)
          @config = config
        end

        def extract(parsed, head_index)
          head = parsed[:head][head_index]
          dates_started_not_empty = parsed[:dates_started].presence ||
            [{}] * (parsed[:dates_finished]&.count || 1)
          dates_started_finished = dates_started_not_empty
            .zip(parsed[:dates_finished] || [])

          experiences_with_dates = dates_started_finished.map { |started, finished|
            {
              spans: spans(started, finished, head, parsed),
              group: started[:group],
              variant_index: (started[:variant] || 1).to_i - 1,
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

        def dates_started_and_finished(parsed)
          dates_started = parsed[:dates_started]&.presence ||
            [{}] * parsed[:dates_finished].count

          [dates_started, parsed[:dates_finished]]
        end

        def progress(hash)
          hash[:progress_time] ||
            hash[:progress_pages]&.to_i ||
            hash[:progress_percent]&.to_i&./(100.0) ||
            (0 if hash[:progress_dnf]) ||
            nil
        end

        def spans(started, finished, head, parsed)
          if !started&.dig(:date) && !finished&.dig(:date)
            dates = nil
          else
            dates = [started, finished].map { |date_hash|
              begin
                Date.parse(date_hash[:date]) if date_hash&.dig(:date)
              rescue Date::Error
                raise InvalidDateError, "Unparsable date \"#{date_hash[:date]}\""
              end
            }
            dates = dates[0]..dates[1]
          end

          variant_index = (started[:variant] || 1).to_i - 1
          length = length(parsed[:sources]&.dig(variant_index)) ||
            length(parsed[:length])

          [
            {
              dates: dates,
              amount: (length if dates),
              progress: progress(started) || progress(head) || (1.0 if finished),
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
