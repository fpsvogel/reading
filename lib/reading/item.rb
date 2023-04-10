require_relative "item/view"
require_relative "config"
require_relative "util/hash_to_data"
require_relative "util/hash_array_deep_fetch"

module Reading
  # A wrapper for an item parsed from a CSV reading log, providing convenience
  # methods beyond what the parser's raw Hash output can provide.
  class Item
    using Util::HashToData
    using Util::HashArrayDeepFetch
    extend Forwardable

    ATTRIBUTES = %i[rating author title genres variants experiences notes]

    private attr_reader :attributes, :config
    attr_reader :status, :view

    def_delegators :attributes, *ATTRIBUTES

    # @param item_hash [Hash] a parsed item like the template in
    #   Config#default_config[:item][:template].
    # @param config [Hash] an entire config.
    # @param view [Class, nil, Boolean] the class that will be used to build the
    #   view object, or nil/false if no view object should be built. If you use
    #   a custom view class, the only requirement is that its #initialize take
    #   an Item and a full config as arguments.
    def initialize(item_hash, config: Config.new.hash, view: Item::View)
      item_hash = item_hash.dup

      add_missing_attributes_with_filler_values(item_hash, config)

      @attributes = item_hash.to_data
      @config = config

      @view = view.new(self, config) if view
    end

    # :done, :in_progress, or :planned.
    # @return [Date, nil]
    def status
      return :planned if experiences.none? || experiences.flat_map(&:spans).none?

      if definite_length?
        last_end_date = experiences.last.spans.last&.dates&.end

        return :done if last_end_date

        return :in_progress
      else # indefinite length
        return :done if indefinite_in_progress_grace_period_over?

        return :in_progress
      end
    end

    # Whether this item has a fixed length, such as a book or audiobook (as
    # opposed to an ongoing podcast).
    # @return [Boolean]
    def definite_length?
      attributes.variants.any? { |variant| !!variant.length }
    end

    def ==(other)
      attributes == other.send(:attributes)
    end

    private

    # For each missing item attribute (key in config[:item][:template]) in
    # item_hash, adds the key and a filler value.
    # @param item_hash [Hash]
    # @param config [Hash] an entire config.
    def add_missing_attributes_with_filler_values(item_hash, config)
      config.deep_fetch(:item, :template).each do |k, v|
        next if item_hash.has_key?(k)

        filler = v.is_a?(Array) ? [] : nil
        item_hash[k] = filler
      end
    end

    # Whether the grace period is over for an indefinite-length item (e.g. podcast)
    # still having an :in_progress status.
    # @return [Boolean]
    def indefinite_in_progress_grace_period_over?
      grace_period = config.deep_fetch(:item, :indefinite_in_progress_grace_period_days)
      last_end_date = experiences
        .select { |experience| experience.spans.any? { |span| span.dates } }
        .last
        .spans
        .select { |span| span.dates }
        .last
        &.dates
        &.end

      return false unless last_end_date

      (Date.today - grace_period) > last_end_date
    end
  end
end
