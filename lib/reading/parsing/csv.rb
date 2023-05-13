# Used throughout, in other files.
require_relative "../util/blank"
require_relative "../util/string_remove"
require_relative "../util/string_truncate"
require_relative "../util/numeric_to_i_if_whole"
require_relative "../util/hash_deep_merge"
require_relative "../util/hash_array_deep_fetch"
require_relative "../util/hash_compact_by_template"
require_relative "../errors"

# Used just here.
require_relative "../config"
require_relative "../item"
require_relative "parser"
require_relative "transformer"

module Reading
  module Parsing
    #
    # Validates a path or lines (string, file, etc.) of a CSV reading log, then
    # parses it into an array of Items.
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
      private attr_reader :parser, :transformer, :hash_output, :item_view

      # Validates a path or lines (string, file, etc.) of a CSV reading log,
      # builds the config, and initializes the parser and transformer.
      # @param path [String] path to the CSV file; used if no lines are given.
      # @param lines [Object] an object responding to #each_line with CSV row(s);
      #   if nil, path is used instead.
      # @param config [Hash] a custom config which overrides the defaults,
      #   e.g. { errors: { styling: :html } }
      # @param hash_output [Boolean] whether an array of raw Hashes should be
      #   returned, without Items being created from them.
      # @param view [Class, nil, Boolean] the class that will be used to build
      #   each Item's view object, or nil/false if no view object should be built.
      #   If you use a custom view class, the only requirement is that its
      #   #initialize take an Item and a full config as arguments.
      def initialize(path = nil, lines: nil, config: {}, hash_output: false, item_view: Item::View)
        validate_path_or_lines(path, lines)
        full_config = Config.new(config).hash

        @path = path
        @lines = lines
        @hash_output = hash_output
        @item_view = item_view
        @parser = Parser.new(full_config)
        @transformer = Transformer.new(full_config)
      end

      # Parses and transforms the reading log into item data.
      # @return [Array<Item>] an array of Items like the template in
      #   Config#default_config[:item][:template]. The Items are identical in
      #   structure to that Hash (with every inner Hash replaced by a Data for
      #   dot access).
      def parse
        input = @lines || File.open(@path)
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

        if hash_output
          items
        else
          items.map { |item_hash| Item.new(item_hash, view: item_view) }
        end
      ensure
        input&.close if input.respond_to?(:close)
      end

      private

      # Checks on the given lines and path (arguments to #initialize).
      # @raise [FileError] if the given path is invalid.
      # @raise [ArgumentError] if both lines and path are nil.
      def validate_path_or_lines(path, lines)
        if lines && lines.respond_to?(:each_line)
          return true
        elsif path
          if !File.exist?(path)
            raise FileError, "File not found! #{path}"
          elsif File.directory?(path)
            raise FileError, "A file is expected, but the path given is a directory: #{path}"
          end
        else
          raise ArgumentError,
            "Provide either a file path or object implementing #each_line (String, File, etc.)."
        end
      end
    end
  end
end
