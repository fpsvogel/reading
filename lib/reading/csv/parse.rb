require_relative "../util/deep_merge"
require_relative "../util/deep_fetch"
require_relative "config"
require_relative "parse_line/parse_regular_line"
require_relative "parse_line/parse_compact_planned_line"

module Reading
  module Csv
    using Util::DeepMerge
    using Util::DeepFetch

    # Parse is a function that parses CSV lines into item data (an array of hashes).
    # For the hash structure, see @default_config[:item][:template] in config.rb
    class Parse
      # @param custom_config [Hash] a custom config which overrides the defaults,
      #   e.g. { errors: { styling: :html } }
      def initialize(custom_config = {})
        @config ||= Reading.build_config(custom_config)
      end

      # Parses item data line by line.
      # @param feed [Object] the input source, which must respond to #each_line.
      # @param close_feed [Boolean] whether the feed should be closed before returning.
      # @param selective [Boolean] if true, parsing is stopped or an item skipped
      #   depending on the return value of the selective_continue proc in config.
      # @param skip_compact_planned [Boolean] whether compact planned items are parsed.
      # @return [Array<Hash>] an array of hashes like the template in config.rb
      def call(
        feed = nil,
        path: nil,
        close_feed: true,
        selective: true,
        skip_compact_planned: false,
        &postprocess
      )
        if feed.nil? && path.nil? && @config.deep_fetch(:csv, :path).nil?
          raise ArgumentError, "No file given to load."
        end

        feed ||= File.open(path || @config.deep_fetch(:csv, :path))
        parse_regular = ParseRegularLine.new(@config)
        parse_compact_planned = ParseCompactPlannedLine.new(@config)
        items = []

        feed.each_line do |line|
          line.force_encoding(Encoding::UTF_8)
          cur_line = line.strip

          case line_type(cur_line)
          when :blank, :comment
            next
          when :regular
            items += parse_regular.call(cur_line, &postprocess)
          when :compact_planned_line
            next if skip_compact_planned
            items += parse_compact_planned.call(cur_line, &postprocess)
          end

          if selective
            continue = @config.deep_fetch(:csv, :selective_continue).call(items.last)
            case continue
            when false
              break
            when :skip
              items.pop
            end
          end
        end

        items

      rescue Errno::ENOENT
        raise FileError.new(path, label: "File not found!")
      rescue Errno::EISDIR
        raise FileError.new(path, label: "The reading list must be a file, not a directory!")
      ensure
        feed&.close if close_feed && feed.respond_to?(:close)
        # Reset to pre-call state.
        initialize
      end

      private

      def line_type(line)
        return :blank if line.empty?

        if starts_with_comment_character?(line)
          return :compact_planned_line if compact_planned_line?(line)
          return :comment
        end
        :regular
      end

      def starts_with_comment_character?(line)
        line.start_with?(@config.deep_fetch(:csv, :comment_character)) ||
          line.match?(/\A\s+#{@config.deep_fetch(:csv, :regex, :comment_escaped)}/)
      end

      def compact_planned_line?(line)
        line.match?(@config.deep_fetch(:csv, :regex, :compact_planned_line_start))
      end
    end
  end
end
