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
require_relative "parser"
require_relative "transformer"

module Reading
  module Parsing
    #
    # Validates a path/string of a CSV reading log, then parses it into item data
    # (an array of Structs).
    #
    # Parsing happens in two steps:
    #   (1) Parse a row string into an intermediate hash representing the columns.
    #       - See parsing/parser.rb, which uses parsing/rows/*
    #   (2) Transform the intermediate hash into an array of hashes structured
    #       around item attributes rather than CSV columns.
    #       - See parsing/transformer.rb, which uses parsing/attributes/*
    #
    # Keeping these steps separate makes the code easier to understand. It was
    # inspired by the Parslet gem: https://kschiess.github.io/parslet/transform.html
    #
    class CSV
      using Util::HashToStruct

      private attr_reader :parser, :transformer

      # Validates a path/string of a CSV reading log, builds the config, and
      # initializes the parser and transformer.
      # @param path [String] path to the CSV file; if nil, string is used instead.
      # @param string [Object] a string of CSV row(s); used if no path is given.
      # @param config [Hash] a custom config which overrides the defaults,
      #   e.g. { errors: { styling: :html } }
      def initialize(path = nil, string: nil, config: {})
        validate_path_or_string(path, string)
        full_config = Config.new(config).hash

        @path = path
        @string = string
        @parser = Parser.new(full_config)
        @transformer = Transformer.new(full_config)
      end

      # Parses and transforms the reading log into item data.
      # @return [Array<Struct>] an array of Structs like the template in
      #   Config#default_config[:item_template]. The Structs are identical in
      #   structure to that Hash (with every inner Hash replaced by a Struct).
      def parse
        input = @path ? File.open(@path) : @string
        items = []

        input.each_line do |line|
          begin
            intermediate = parser.parse_row_to_intermediate_hash(line)
            next if intermediate.empty? # When the row is blank or a comment.
            row_items = transformer.transform_intermediate_hash_to_item_hashes(intermediate)
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
      def validate_path_or_string(path, string)
        if path
          if !File.exist?(path)
            raise FileError, "File not found! #{path}"
          elsif File.directory?(path)
            raise FileError, "A file is expected, but the path given is a directory: #{path}"
          end
        # string doesn't HAVE to be a String; it can be any input with #each_line.
        elsif string && string.respond_to?(:each_line)
          return true
        else
          raise ArgumentError, "Either a string or a file path must be provided."
        end
      end
    end
  end
end
