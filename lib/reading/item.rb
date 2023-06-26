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

    private attr_reader :data
    attr_reader :view

    def_delegators :data, *ATTRIBUTES

    # @param item_hash_or_data [Hash, Data] a parsed item Hash like the template
    #   in Config#default_config[:item][:template]; or a Data from another Item.
    # @param config [Hash] an entire config.
    # @param view [Class, nil, Boolean] the class that will be used to build the
    #   view object, or nil/false if no view object should be built. If you use
    #   a custom view class, the only requirement is that its #initialize take
    #   an Item and a full config as arguments.
    def initialize(item_hash_or_data, config: Reading.default_config, view: Item::View)
      if item_hash_or_data.is_a? Data
        @data = item_hash_or_data
      elsif item_hash_or_data.is_a? Hash
        item_hash = item_hash_or_data.dup

        add_missing_attributes_with_filler_values!(item_hash, config)
        add_statuses_and_last_end_dates!(item_hash, config)

        @data = item_hash.to_data
      end

      @view = view.new(self, config) if view
    end

    # This item's status.
    # @return [Symbol] :planned, :in_progress, or :done
    def status
      data.experiences.last&.status || :planned
    end

    # Whether this item is done.
    # @return [Boolean]
    def done?
      status == :done
    end

    # This item's last end date.
    # @return [Date, nil]
    def last_end_date
      data.experiences.last&.last_end_date
    end

        # Returns a new Item containing shallow copy of @data, with its experiences
    # replaced with new_experiences.
    # @param new_experiences [Array<Data>]
    # @param view [Class, nil, Boolean]
    # @return [Item]
    def with_experiences(new_experiences, view: false)
      new_variants = variants.filter.with_index { |variant, old_index|
        new_experiences.any? { _1.variant_index == old_index }
      }

      with_variants(
        new_variants,
        new_experiences:,
        view:,
      )
    end

    # Returns a new Item containing shallow copy of @data, with its variants
    # replaced with new_variants.
    # @param new_variants [Array<Data>]
    # @param new_experiences [Array<Data>]
    # @param view [Class, nil, Boolean]
    # @return [Item]
    def with_variants(new_variants, new_experiences: nil, view: false)
      updated_variant_indices = []

      # Map old to new indices, omitting those of variants that are not in new_variants.
      variants.each.with_index { |variant, old_index|
        new_index = new_variants.index(variant)
        updated_variant_indices[old_index] = [new_index] if new_index
      }

      # Remove experiences associated with the removed variants.
      kept_experiences = (new_experiences || experiences).filter { |experience|
        # Conditional in case Item was created with fragmentary experience hashes,
        # as in stats_test.rb
        variant_index = experience.variant_index if experience.members.include?(:variant_index)

        !!updated_variant_indices[variant_index || 0]
      }

      # Then update the kept experiences' variant indices.
      updated_kept_experiences = kept_experiences.map { |experience|
        updated_variant_index = updated_variant_indices[experience.variant_index]
        experience.with(variant_index: updated_variant_index)
      }

      self.class.new(
        data.with(
          variants: new_variants,
          experiences: updated_kept_experiences,
        ),
        view:,
      )
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
    def add_missing_attributes_with_filler_values!(item_hash, config)
      config.deep_fetch(:item, :template).each do |k, v|
        next if item_hash.has_key?(k)

        filler = v.is_a?(Array) ? [] : nil
        item_hash[k] = filler
      end
    end

    # Determines the status and the last end date of each experience, and adds
    # it into the experience hash. Note: for an item of indefinite length (e.g.
    # podcast) there is a grace period during which the status remains
    # :in_progress after the last activity. If that grace period is over, the
    # status is :done. It's :planned if there are no spans with dates.
    # @param item_hash [Hash]
    # @param config [Hash] an entire config.
    # @return [Array(Symbol, Date)]
    def add_statuses_and_last_end_dates!(item_hash, config)
      item_hash[:experiences] = item_hash[:experiences].dup

      item_hash[:experiences].each do |experience|
        experience[:status] = :planned
        experience[:last_end_date] = nil

        next unless experience[:spans]&.any? { |span|
          span[:dates]
        }

        experience[:status] = :in_progress

        experience[:last_end_date] = experience[:spans]
          .select { |span| span[:dates] }
          .last[:dates]
          .end

        next unless experience[:last_end_date]

        # Whether this item has a fixed length, such as a book or audiobook (as
        # opposed to e.g. an ongoing podcast).
        has_definite_length =
          !!item_hash[:variants][experience[:variant_index] || 0]&.dig(:length)

        if has_definite_length
          experience[:status] = :done
        else
          grace_period = config.deep_fetch(
            :item,
            :indefinite_in_progress_grace_period_days,
          )

          indefinite_in_progress_grace_period_is_over =
            (Date.today - grace_period) > experience[:last_end_date]

          if indefinite_in_progress_grace_period_is_over
            experience[:status] = :done
          end
        end
      end
    end
  end
end
