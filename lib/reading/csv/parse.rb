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
    # For the structure of these hashes, see @config[:item] in config.rb
    class Parse
      def initialize(custom_config = {})
        @config ||= Reading.build_config(custom_config)
      end

      # - Returns a hash of item data in the same order as they arrive from feed.
      # - feed is anything with #each_line.
      # - close_feed determines whether the feed is closed before returning.
      # - If selective is true, parsing is stopped or an item skipped depending
      #   on the return value of the selective_continue proc in config.
      # - skip_compact_planned determines whether compact planned items are parsed.
      # - postprocess can be used to convert the data hashes into Items. this
      #   way Item can access the CSV source line, which is useful since Item
      #   does additional validation on the data, and in case of any errors it
      #   can pass along the source line to an error message.
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

          # This could be refactored into LineType classes (BlankLine, CommentLine, etc.)
          # each with a #line_match? method and an associated action for a match,
          # but this abstraction wouldn't be justified because I doubt there'll
          # be any additional line types in the future, besides the four types here.
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
