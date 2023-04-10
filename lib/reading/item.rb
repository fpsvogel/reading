require_relative "item/view"
require_relative "config"
require_relative "util/hash_to_data"
require_relative "util/hash_array_deep_fetch"

module Reading
  # A wrapper for an item parsed from a CSV reading log, providing convenience
  # methods beyond what the parser's raw Hash output can provide.
  class Item
    using Util::HashToData
    extend Forwardable

    ATTRIBUTES = %i[rating author title genres variants experiences notes]

    private attr_reader :data
    attr_reader :status, :view

    def_delegators :data, *ATTRIBUTES

    # @param item_hash [Hash] a parsed item like the template in
    #   Config#default_config[:item_template].
    # @param config [Hash] an entire config.
    # @param view [Class, nil, Boolean] the class that will be used to build the
    #   view object, or nil/false if no view object should be built. If you use
    #   a custom view class, the only requirement is that its #initialize take
    #   an Item and a full config as arguments.
    def initialize(item_hash, config: Config.new.hash, view: Item::View)
      item_hash = item_hash.dup

      add_missing_attributes_with_filler_values(item_hash, config)

      @data = item_hash.to_data

      @view = view.new(self, config) if view
    end

    # :done, :in_progress, or :planned.
    # TODO: return :in_progress for indefinite-length items (e.g. podcasts) that
    # have a recent span.
    # @return [Date, nil]
    def status
      if experiences.any? && experiences.flat_map(&:spans).any?
        last_end_date = experiences.last.spans.last&.dates&.end
        if last_end_date
          return :done
        else
          return :in_progress
        end
      end

      :planned
    end

    def ==(other)
      data == other.send(:data)
    end

    private

    # For each missing item attribute (key in config[:item_template) in
    # item_hash, adds the key and a filler value.
    # @param item_hash [Hash]
    # @param config [Hash] an entire config.
    def add_missing_attributes_with_filler_values(item_hash, config)
      config.fetch(:item_template).each do |k, v|
        next if item_hash.has_key?(k)

        filler = v.is_a?(Array) ? [] : nil
        item_hash[k] = filler
      end
    end
  end
end
