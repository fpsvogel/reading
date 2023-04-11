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
      else
        status_of_indefinite_length_item
      end
    end

    # Whether this item has a fixed length, such as a book or audiobook (as
    # opposed to an ongoing podcast).
    # @return [Boolean]
    def definite_length?
      attributes.variants.any? { |variant| !!variant.length }
    end

    def ==(other)
      unless other.is_a?(Item)
        raise ArgumentError, "An Item can be compared only with another Item."
      end

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

    # For an indefinite-length item (e.g. podcast). There is a grace period
    # during which the status remains :in_progress after the last activity. If
    # that grace period is over, the status is :done. It's :planned if there
    # are no spans with dates.
    # @return [Symbol] :planned, :in_progress, :done
    def status_of_indefinite_length_item
      grace_period = config.deep_fetch(:item, :indefinite_in_progress_grace_period_days)
      experiences_with_spans_with_dates = experiences
        .select { |experience| experience.spans.any? { |span| span.dates } }

      return :planned unless experiences_with_spans_with_dates.any?

      last_end_date = experiences_with_spans_with_dates
        .last
        .spans
        .select { |span| span.dates }
        .last
        .dates
        .end

      return :in_progress unless last_end_date

      indefinite_in_progress_grace_period_over =
        (Date.today - grace_period) > last_end_date

      return :done if indefinite_in_progress_grace_period_over

      :in_progress
    end
  end
end
