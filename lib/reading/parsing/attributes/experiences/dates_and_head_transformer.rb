require_relative 'spans_validator'

module Reading
  module Parsing
    module Attributes
      class Experiences < Attribute
        # Experiences#transform_from_parsed delegates to this class when the
        # History column is blank (i.e. when experiences should be extracted
        # from the Start Dates, End Dates, and Head columns).
        class DatesAndHeadTransformer
          using Util::HashArrayDeepFetch

          private attr_reader :config, :parsed_row, :head_index

          # @param parsed_row [Hash] a parsed row (the intermediate hash).
          # @param head_index [Integer] current item's position in the Head column.
          # @param config [Hash] an entire config.
          def initialize(parsed_row, head_index, config)
            @config = config
            @parsed_row = parsed_row
            @head_index = head_index
          end

          # Extracts experiences from the parsed row.
          # @return [Array<Hash>] an array of experiences; see
          #   Config#default_config[:item][:template][:experiences]
          def transform
            size = [parsed_row[:start_dates]&.count || 0, parsed_row[:end_dates]&.count || 0].max
            # Pad start dates with {} and end dates with nil up to the size of
            # the larger of the two.
            start_dates = Array.new(size) { |i| parsed_row[:start_dates]&.dig(i) || {} }
            end_dates = Array.new(size) { |i| parsed_row[:end_dates]&.dig(i) || nil }

            start_end_dates = start_dates.zip(end_dates).presence || [[{}, nil]]

            experiences_with_dates = start_end_dates.map { |start_entry, end_entry|
              {
                spans: spans(start_entry, end_entry),
                group: start_entry[:group],
                variant_index: (start_entry[:variant] || 1).to_i - 1,
              }.map { |k, v| [k, v || template.fetch(k)] }.to_h
            }.presence

            if experiences_with_dates
              # Raises an error if any sequence of dates does not make sense.
              Experiences::SpansValidator.validate(experiences_with_dates, config)
            end

            experiences_with_dates
          end

          private

          # A shortcut to the experience template.
          # @return [Hash]
          def template
            config.deep_fetch(:item, :template, :experiences).first
          end

          # A shortcut to the span template.
          # @return [Hash]
          def span_template
            config.deep_fetch(:item, :template, :experiences, 0, :spans).first
          end

          # The :spans sub-attribute for the given pair of date entries.
          # single span in an array.
          # @param start_entry [Hash] a parsed entry in the Start Dates column.
          # @param end_entry [Hash] a parsed entry in the End Dates column.
          # @return [Array(Hash)] an array containing a single span representing
          #   the start and end date.
          def spans(start_entry, end_entry)
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
            format = parsed_row[:sources]&.dig(variant_index)&.dig(:format) ||
              parsed_row[:head][head_index][:format]
            length = Attributes::Shared.length(parsed_row[:sources]&.dig(variant_index), config, format:) ||
              Attributes::Shared.length(parsed_row[:length], config, format:)

            [
              {
                dates: dates,
                amount: (length if dates),
                progress: Attributes::Shared.progress(start_entry, config) ||
                  Attributes::Shared.progress(parsed_row[:head][head_index], config) ||
                  (1.0 if end_entry),
                name: span_template.fetch(:name),
                favorite?: span_template.fetch(:favorite?),
              }.map { |k, v| [k, v || span_template.fetch(k)] }.to_h
            ]
          end
        end
      end
    end
  end
end
