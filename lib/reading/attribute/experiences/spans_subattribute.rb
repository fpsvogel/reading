module Reading
  class Row
    class SpansSubattribute
      using Util::HashArrayDeepFetch

      private attr_reader :date_entry, :dates_finished, :date_index, :variant_index, :columns, :config

      # @param date_entry [String] the entry in Dates Started.
      # @param dates_finished [Array<String>] the entries in Dates Finished.
      # @param date_index [Integer] the index of the entry.
      # @param variant_index [Integer] the variant index, for getting length for default amount.
      # @param columns [Array<String>]
      # @param config [Hash]
      def initialize(date_entry:, dates_finished:, date_index:, variant_index:, columns:, config:)
        @date_entry = date_entry
        @dates_finished = dates_finished
        @date_index = date_index
        @variant_index = variant_index
        @columns = columns
        @config = config
      end

      def parse
        started = date_started(date_entry)
        finished = date_finished(dates_finished, date_index)
        return [] if started.nil? && finished.nil?

        sources_str = columns[:sources]&.presence || " "
        bare_variant = sources_str
          .split(config.deep_fetch(:csv, :regex, :formats_split))
          .dig(variant_index)
          &.split(config.deep_fetch(:csv, :long_separator))
          &.first
        length_attr = LengthSubattribute.new(bare_variant:, columns:, config:)
        length = length_attr.parse

        progress_attr = ProgressSubattribute.new(date_entry:, variant_index:, columns:, config:)
        progress = progress_attr.parse

        [{
          dates: started..finished,
          amount: length,
          progress: progress || (1.0 if finished),
          name: nil,
          favorite?: false,
        }]
      end

      private

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
    end
  end
end
