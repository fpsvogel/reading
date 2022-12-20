require_relative "util/deep_merge"
require_relative "util/deep_fetch"
require_relative "util/to_struct"
require_relative "config"
require_relative "line"

module Reading
  class CSV
    using Util::DeepMerge
    using Util::DeepFetch
    using Util::ToStruct

    attr_reader :config

    # @param feed [Object] the input source, which must respond to #each_line;
    #   if nil, the file at the given path is used.
    # @param path [String] the path of the source file.
    # @param config [Hash] a custom config which overrides the defaults,
    #   e.g. { errors: { styling: :html } }
    def initialize(feed = nil, path: nil, config: {})
      if feed.nil? && path.nil?
        raise ArgumentError, "No file given to load."
      end

      if path
        if !File.exist?(path)
          raise FileError, "File not found! #{@path}"
        elsif File.directory?(path)
          raise FileError, "The reading log must be a file, but the path given is a directory: #{@path}"
        end
      end

      @feed = feed
      @path = path
      @config ||= Config.new(config).hash
    end

    # Parses a CSV reading log into item data (an array of Structs).
    # For what the Structs look like, see the Hash at @default_config[:item][:template]
    # in config.rb. The Structs are identical in structure to that Hash (with
    # every inner Hash replaced with a Struct).
    # @return [Array<Struct>] an array of Structs like the template in config.rb
    def parse
      feed = @feed || File.open(@path)
      items = []

      feed.each_line do |string|
        line = Line.new(string, self)
        row = line.to_row

        items += row.parse
      end

      items.map(&:to_struct)
    ensure
      feed&.close if feed.respond_to?(:close)
    end
  end
end
