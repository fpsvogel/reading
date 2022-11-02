require_relative "../util/deep_merge"
require_relative "../util/deep_fetch"
require_relative "config"
require_relative "line"

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
    # @return [Array<Hash>] an array of hashes like the template in config.rb
    def parse(feed = nil, path: nil)
      path ||= @config.deep_fetch(:csv, :path)

      if feed.nil? && path.nil?
        raise ArgumentError, "No file given to load."
      end

      feed ||= File.open(path || @config.deep_fetch(:csv, :path))
      items = []

      feed.each_line do |string|
        line = Line.new(string, self)
        row = line.to_row

        items += row.parse
      end

      items

    rescue Errno::ENOENT
      raise FileError.new("File not found! #{path}")
    rescue Errno::EISDIR
      raise FileError.new("The reading list must be a file, but the path given is a directory: #{path}")
    ensure
      feed&.close if feed.respond_to?(:close)
    end
  end
end
