require_relative "../util/deep_merge"
require_relative "../util/deep_fetch"
require_relative "config"
require_relative "row/regular_row"
require_relative "row/compact_planned_row"

module Reading
  class CSV
    using Util::DeepMerge
    using Util::DeepFetch

    attr_reader :config

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
      items = []

      feed.each_line do |line|
        row = Row.from_line(line, self, skip_compact_planned:)
        next unless row

        items += row.parse(line)

        # TODO redesign selective continue, to avoid `next unless row` above
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
  end
end
