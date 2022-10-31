require_relative "../util/deep_merge"
require_relative "../util/deep_fetch"
require_relative "config"
require_relative "row/regular_row"
require_relative "row/compact_planned_row"

module Reading
  class CSV
    using Util::DeepMerge
    using Util::DeepFetch

    # @param custom_config [Hash] a custom config which overrides the defaults,
    #   e.g. { errors: { styling: :html } }
    def initialize(custom_config = {})
      @config ||= Reading.build_config(custom_config)
    end

    # Parses a CSV reading log into item data (an array of hashes).
    # For the hash structure, see @default_config[:item][:template] in config.rb
    # @param feed [Object] the input source, which must respond to #each_line;
    #   if nil, the file at the given path or at @config[:csv][:path] is used.
    # @param path [String] of the source file; if nil, @config[:csv][:path] is used.
    # @param close_feed [Boolean] whether the feed should be closed before returning.
    # @param selective [Boolean] if true, parsing is stopped or an item skipped
    #   depending on the return value of the selective_continue proc in config.
    # @param skip_compact_planned [Boolean] whether compact planned items are parsed.
    # @return [Array<Hash>] an array of hashes like the template in config.rb
    def parse(
      feed = nil,
      path: nil,
      close_feed: true,
      selective: true,
      skip_compact_planned: false
    )
      if feed.nil? && path.nil? && @config.deep_fetch(:csv, :path).nil?
        raise ArgumentError, "No file given to load."
      end

      feed ||= File.open(path || @config.deep_fetch(:csv, :path))
      regular_row = RegularRow.new(@config)
      compact_planned_row = CompactPlannedRow.new(@config)
      items = []

      feed.each_line do |row|
        row.force_encoding(Encoding::UTF_8)
        cur_row = row.strip

        case row_type(cur_row)
        when :blank, :comment
          next
        when :regular
          items += regular_row.parse(cur_row)
        when :compact_planned_row
          next if skip_compact_planned
          items += compact_planned_row.parse(cur_row)
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

    def row_type(row)
      return :blank if row.empty?

      if starts_with_comment_character?(row)
        return :compact_planned_row if compact_planned_row?(row)
        return :comment
      end
      :regular
    end

    def starts_with_comment_character?(row)
      row.start_with?(@config.deep_fetch(:csv, :comment_character)) ||
        row.match?(/\A\s+#{@config.deep_fetch(:csv, :regex, :comment_escaped)}/)
    end

    def compact_planned_row?(row)
      row.match?(@config.deep_fetch(:csv, :regex, :compact_planned_row_start))
    end
  end
end
