# Used throughout, in other files.
require_relative "../util/blank"
require_relative "../util/string_remove"
require_relative "../util/string_truncate"
require_relative "../util/hash_to_struct"
require_relative "../util/hash_deep_merge"
require_relative "../util/hash_array_deep_fetch"
require_relative "../util/hash_compact_by_template"
require_relative "../errors"

# Used just here.
require_relative "../config"
require_relative "parse"
require_relative "transform"

module Reading
  module Parser
    class CSV
      using Util::HashToStruct

      private attr_reader :parser, :transformer

      # @param string [Object] the input source, which must respond to #each_line;
      #   if nil, the file at the given path is used.
      # @param path [String] the path of the source file.
      # @param config [Hash] a custom config which overrides the defaults,
      #   e.g. { errors: { styling: :html } }
      def initialize(string = nil, path: nil, config: {})
        validate_string_or_path(string, path)
        full_config = Config.new(config).hash

        @string = string
        @path = path
        @parser = Parse.new(full_config)
        @transformer = Transform.new(full_config)
      end

      # Parses a CSV reading log into item data (an array of Structs).
      # @return [Array<Struct>] an array of Structs like the template in
      #   Config#default_config[:item][:template]. The Structs are identical in
      #   structure to that Hash (with every inner Hash replaced by a Struct).
      def parse
        input = @string || File.open(@path)
        items = []

        input.each_line do |line|
          begin
            parsed = parser.parse_row_to_intermediate_hash(line)
            next if parsed.empty?
            row_items = transformer.transform_intermediate_hash_to_item_hashes(parsed)
          rescue Reading::Error => e
            raise e.class, "#{e.message} in the row \"#{line}\""
          end

          items += row_items
        end

        items.map(&:to_struct)
      ensure
        input&.close if input.respond_to?(:close)
      end

      private

      # Checks on the given string and path (arguments to #initialize).
      # @raise [FileError] if the given path is invalid.
      # @raise [ArgumentError] if both string and path are nil.
      def validate_string_or_path(string, path)
        return true if string && string.respond_to?(:each_line)

        if path
          if !File.exist?(path)
            raise FileError, "File not found! #{path}"
          elsif File.directory?(path)
            raise FileError, "A file is expected, but the path given is a directory: #{path}"
          end
        else
          raise ArgumentError, "Either a string or a file path must be provided."
        end
      end
    end
  end
end