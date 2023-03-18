require "date"
require_relative "experiences/dates_validator"

module Reading
  module Parser
    module Attributes
      class Experiences
        using Util::HashArrayDeepFetch
        using Util::HashDeepMerge

        class << self
          private attr_reader :config

          def extract(parsed, head_index, config)
            @config = config

            head = parsed[:head][head_index]
            dates_started_not_empty = parsed[:dates_started].presence ||
              [{}] * parsed[:dates_finished].count
            dates_started_finished = dates_started_not_empty
              .zip(parsed[:dates_finished])

            experiences_with_dates = dates_started_finished.map { |started, finished|
              {
                spans: spans(started, finished, head, parsed),
                group: started[:group],
                variant_index: started[:variant].to_i - 1,
              }.map { |k, v| [k, v || template.fetch(k)] }.to_h
            }.presence

            if experiences_with_dates
              # Raises an error if any sequence of dates does not make sense.
              Experiences::DatesValidator.validate(experiences_with_dates, config)

              return experiences_with_dates
            else
              if progress_in_head = progress(head)
                return [template.deep_merge(spans: [{ progress: progress_in_head }])]
              else
                return template
              end
            end
          end

          private

          def template
            config.deep_fetch(:item, :template, :experiences).first
          end

          def spans_template
            config.deep_fetch(:item, :template, :experiences, 0, :spans).first
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
            return [] if started[:date].nil? && finished[:date].nil?
            variant_index = started[:variant].to_i - 1

            [
              {
                dates: Date.parse(started[:date])..Date.parse(finished[:date]),
                amount: length(parsed[:sources][variant_index]) ||
                  length(parsed[:length]),
                progress: progress(started) || progress(head) || (1.0 if finished),
                name: spans_template.fetch(:name),
                favorite?: spans_template.fetch(:favorite?),
              }.map { |k, v| [k, v || spans_template.fetch(k)] }.to_h
            ]
          end

          def length(hash)
            hash[:length_time] ||
              hash[:length_pages]&.to_i
          end
        end
      end
    end
  end
end
