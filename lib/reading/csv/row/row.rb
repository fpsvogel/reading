require_relative "../../errors"
require_relative "../../util/deep_fetch"
require_relative "../../util/compact_by_template"

module Reading
  class CSV
    # A base class that contains behaviors common to ___Row classes.
    class Row
      using Util::DeepFetch
      using Util::CompactByTemplate

      private attr_reader :line

      # @param line [Line] the Line that this Row represents.
      def initialize(line)
        @line = line

        after_initialize
      end

      # Parses a CSV row into an array of hashes of item data. How this is done
      # depends on how the template methods (further below) are implemented in
      # subclasses of Row.
      # @return [Array<Hash>] an array of hashes like the template in config.rb
      def parse
        return [] if skip?

        before_parse

        items = split_by_format_emojis.map { |name|
          item_hash(name)
            .compact_by(template: config.deep_fetch(:item, :template))
        }.compact

        items

      rescue InvalidItemError, StandardError => e
        # TODO instead of rescuing StandardError here, test missing
        # initial/middle columns in ParseRegularRow#set_columns, and raise
        # appropriate errors if possible.
        unless e.is_a? InvalidItemError
          if config.deep_fetch(:errors, :catch_all_errors)
            e = InvalidItemError.new("A row could not be parsed. Check this row")
          else
            raise e
          end
        end

        e.handle(line:)
        []
      end

      private

      def string
        @line.string
      end

      def config
        @line.csv.config
      end

      def split_by_format_emojis
        multi_items_to_be_split_by_format_emojis
          .split(config.deep_fetch(:csv, :regex, :formats_split))
          .tap { |names|
            names.first.sub!(config.deep_fetch(:csv, :regex, :dnf), "")
            names.first.sub!(config.deep_fetch(:csv, :regex, :progress), "")
          }
          .map { |name| name.strip.sub(/\s*,\z/, "") }
          .partition { |name| name.match?(/\A#{config.deep_fetch(:csv, :regex, :formats)}/) }
          .reject(&:empty?)
          .first
      end

      # Below: template methods that can (or must) be overridden.

      def after_initialize
      end

      def before_parse
      end

      def skip?
        false
      end

      def multi_items_to_be_split_by_format_emojis
        raise NotImplementedError, "#{self.class} should have implemented #{__method__}"
      end

      def item_hash(name)
        raise NotImplementedError, "#{self.class} should have implemented #{__method__}"
      end
    end
  end
end
