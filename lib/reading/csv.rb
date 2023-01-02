# Used throughout, in other files.
require_relative "util/blank"
require_relative "util/string_remove"
require_relative "util/string_truncate"
require_relative "util/hash_to_struct"
require_relative "util/hash_deep_merge"
require_relative "util/hash_array_deep_fetch"
require_relative "util/hash_compact_by_template"
require_relative "errors"

# Used just here.
require_relative "config"
require_relative "line"

module Reading
  class CSV
    using Util::HashDeepMerge
    using Util::HashArrayDeepFetch
    using Util::HashToStruct

    attr_reader :config

    # @param feed [Object] the input source, which must respond to #each_line;
    #   if nil, the file at the given path is used.
    # @param path [String] the path of the source file.
    # @param config [Hash] a custom config which overrides the defaults,
    #   e.g. { errors: { styling: :html } }
    def initialize(feed = nil, path: nil, config: {})
      validate_feed_or_path(feed, path)

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

    private

    # Checks on the given feed and path (arguments to #initialize).
    # @raise [FileError] if the given path is invalid.
    # @raise [ArgumentError] if both feed and path are nil.
    def validate_feed_or_path(feed, path)
      return true if feed

      if path
        if !File.exist?(path)
          raise FileError, "File not found! #{path}"
        elsif File.directory?(path)
          raise FileError, "The reading log must be a file, but the path given is a directory: #{path}"
        end
      else
        raise ArgumentError, "Either a feed (String, File, etc.) or a file path must be provided."
      end
    end
  end
end
