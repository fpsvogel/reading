module Reading
  module Parsing
    module Rows
      # A row that declares custom config.
      module CustomConfig
        using Util::HashArrayDeepFetch

        # No columns; parsed as if the row were blank.
        # @return [Array]
        def self.column_classes
          []
        end

        # Starts with a comment character and opening curly brace, and ends with
        # a closing curly brace.
        # @param row_string [String]
        # @return [Boolean]
        def self.match?(row_string)
          row_string.match?(
            %r{\A
              \s*
              #{Regexp.escape(Config.hash.fetch(:comment_character))}
              \s*
              \{.+\}
              \s*
            \z}x
          )
        end

        # Adds this row's custom config to the singleton config.
        # @param row_string [String]
        # @param config [Hash] an entire config.
        def self.merge_custom_config!(row_string)
          stripped_row = row_string.strip.delete_prefix(Config.hash.fetch(:comment_character))
          custom_config = eval(stripped_row)

          Config.hash.merge!(custom_config)
        end
      end
    end
  end
end
