module Reading
  class Row
    class ProgressSubattribute
      using Util::HashArrayDeepFetch

      private attr_reader :date_entry, :variant_index, :columns, :config

      # @param date_entry [String] the entry in Dates Started.
      # @param variant_index [Integer] the variant index, for getting length for default amount.
      # @param columns [Array<String>]
      # @param config [Hash]
      def initialize(date_entry: nil, variant_index: nil, columns:, config:)
        @date_entry = date_entry
        @variant_index = variant_index
        @columns = columns
        @config = config
      end

      def parse
        progress(date_entry) || progress(columns[:head])
      end

      def parse_head_only
        progress(columns[:head])
      end

      private

      def progress(str)
        prog = str.match(config.deep_fetch(:csv, :regex, :progress))

        if prog
          if prog_percent = prog[:percent]&.to_i
            return prog_percent / 100.0
          elsif prog_time = prog[:time]
            return prog_time
          elsif prog_pages = prog[:pages]&.to_i
            return prog_pages
          end
        end

        dnf = str.match(config.deep_fetch(:csv, :regex, :dnf))&.captures&.first
        return 0 if dnf
        nil
      end
    end
  end
end
