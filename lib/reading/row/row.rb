module Reading
  # A base class that contains behaviors common to ___Row classes.
  class Row
    using Util::StringRemove
    using Util::HashArrayDeepFetch
    using Util::HashCompactByTemplate

    private attr_reader :line

    # @param line [Reading::Line] the Line that this Row represents.
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

      items = item_heads.map { |item_head|
        item_hash(item_head)
          .compact_by(template: config.deep_fetch(:item, :template))
      }.compact

      items

    rescue Reading::Error, StandardError => e
      # TODO instead of rescuing StandardError here, test missing
      # initial/middle columns in ParseRegularRow#set_columns, and raise
      # appropriate errors if possible.
      unless e.is_a? Reading::Error
        if config.deep_fetch(:errors, :catch_all_errors)
          e = Reading::Error.new("A row could not be parsed. Check this row")
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

    # A "head" is a string in the Head column containing a chunk of item
    # information, starting with a format emoji. A typical row describes one
    # item and so contains one head, but a row describing multiple items (with
    # multiple heads in the Head column) is possible. Also, a row of compact
    # planned items is essentially a list of heads, though with different
    # elements than a normal row's head.
    # @return [Array<String>]
    def item_heads
      string_to_be_split_by_format_emojis
        .split(config.deep_fetch(:csv, :regex, :formats_split))
        .tap { |item_heads|
          item_heads.first.remove!(config.deep_fetch(:csv, :regex, :dnf))
          item_heads.first.remove!(config.deep_fetch(:csv, :regex, :progress))
        }
        .map { |item_head| item_head.strip }
        .partition { |item_head| item_head.match?(/\A#{config.deep_fetch(:csv, :regex, :formats)}/) }
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

    def string_to_be_split_by_format_emojis
      raise NotImplementedError, "#{self.class} should have implemented #{__method__}"
    end

    def item_hash(item_head)
      raise NotImplementedError, "#{self.class} should have implemented #{__method__}"
    end
  end
end
