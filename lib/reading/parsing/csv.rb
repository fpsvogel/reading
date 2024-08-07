require "pastel"
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
      private attr_reader :parser, :transformer, :hash_output, :item_view, :error_handler, :pastel

      # Validates a path or lines (string, file, etc.) of a CSV reading log,
      # builds the config, and initializes the parser and transformer.
      # @param path [String] path to the CSV file; used if no lines are given.
      # @param lines [Object] an object responding to #each_line with CSV row(s);
      #   if nil, path is used instead.
      # @param config [Hash, Config] a custom config which overrides the defaults,
      #   e.g. { errors: { styling: :html } }
      # @param hash_output [Boolean] whether an array of raw Hashes should be
      #   returned, without Items being created from them.
      # @param item_view [Class, nil, Boolean] the class that will be used to build
      #   each Item's view object, or nil/false if no view object should be built.
      #   If you use a custom view class, the only requirement is that its
      #   #initialize take an Item and a full config as arguments.
      # @param error_handler [Proc] if not provided, errors are raised.
      def initialize(path: nil, lines: nil, config: nil, hash_output: false, item_view: Item::View, error_handler: nil)
        validate_path_or_lines(path, lines)

        Config.build(config) if config

        @path = path
        @lines = lines
        @hash_output = hash_output
        @item_view = item_view
        @parser = Parser.new
        @transformer = Transformer.new
        @error_handler = error_handler
        @pastel = Pastel.new
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
            colored_e =
              e.class.new("#{pastel.bright_red(e.message)} in the row #{pastel.bright_yellow(line.chomp)}")

            if error_handler
              error_handler.call(colored_e)
              next
            else
              raise colored_e
            end
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
