require 'forwardable'

require_relative 'item/view'

module Reading
  # A wrapper for an item parsed from a CSV reading log, providing convenience
  # methods beyond what the parser's raw Hash output can provide.
  class Item
    using Util::HashToData
    using Util::HashArrayDeepFetch
    extend Forwardable

    ATTRIBUTES = %i[rating author title genres variants experiences notes]

    private attr_reader :data, :config
    attr_reader :view, :status, :last_end_date

    def_delegators :data, *ATTRIBUTES

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

      @data = item_hash.to_data

      @status, @last_end_date = get_status_and_last_end_date(config)
      @view = view.new(self, config) if view
    end

    # Whether this item is done.
    # @return [Boolean]
    def done?
      status == :done
    end

    # Whether this item has a fixed length, such as a book or audiobook (as
    # opposed to an ongoing podcast).
    # @return [Boolean]
    def definite_length?
      data.variants.any? { |variant| !!variant.length }
    end

    # Equality to another Item.
    # @other [Item]
    # @return [Boolean]
    def ==(other)
      unless other.is_a?(Item)
        raise ArgumentError, "An Item can be compared only with another Item."
      end

      data == other.send(:data)
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

    # Determines the status and the last end date. Note: for an item of indefinite
    # length (e.g. podcast) there is a grace period during which the status
    # remains :in_progress after the last activity. If that grace period is over,
    # the status is :done. It's :planned if there are no spans with dates.
    # @param config [Hash] an entire config.
    # @return [Array(Symbol, Date)]
    def get_status_and_last_end_date(config)
      return [:planned, nil] if experiences.none? ||
        experiences.flat_map { |experience|
          # Conditional in case Item was created with fragmentary experience hashes,
          # as in stats_test.rb
          experience.spans if experience.members.include?(:spans)
        }
        .none?

      experiences_with_spans_with_dates = experiences
        .select { |experience|
          experience.spans.any? { |span|
            # Conditional in case Item was created with fragmentary experience hashes,
            # as in stats_test.rb
            span.dates if span.members.include?(:dates)
          }
        }

      return [:planned, nil] unless experiences_with_spans_with_dates.any?

      last_end_date = experiences_with_spans_with_dates
        .last
        .spans
        .select { |span| span.dates }
        .last
        .dates
        .end

      return [:in_progress, nil] unless last_end_date

      if definite_length?
        [:done, last_end_date]
      else
        grace_period = config.deep_fetch(:item, :indefinite_in_progress_grace_period_days)
        indefinite_in_progress_grace_period_is_over =
          (Date.today - grace_period) > last_end_date

        return [:done, last_end_date] if indefinite_in_progress_grace_period_is_over

        [:in_progress, last_end_date]
      end
    end
  end
end
