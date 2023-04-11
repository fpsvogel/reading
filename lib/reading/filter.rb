module Reading
  # Filters Items based on given criteria.
  class Filter
    class << self
      # Filters Items based on given criteria, and returns them sorted by last
      # end date or (where there is none) status, where :planned Items are
      # placed last, and :in_progress just before those.
      # @param items [Array<Item>]
      # @param no_sort [Boolean] to preserve the original ordering of the Items.
      # @param kwargs [Hash] one or more of the filters defined in by_x methods below.
      # @return [Array<Item>]
      # @raise [ArgumentError] if kwargs are invalid or missing.
      def by(**kwargs)
        filters_and_args, items, no_sort = split_kwargs(kwargs)

        filtered = filters_and_args.each.with_object(items.dup) { |(filter, arg), filtered_items|
          send("#{FILTER_PREFIX}#{filter}#{FILTER_SUFFIX}", filtered_items, arg)
        }

        return filtered if no_sort

        filtered.sort_by { |item|
          if item.done?
            item.last_end_date.strftime("%Y-%m-%d")
          else
            item.status.to_s
          end
        }
      end

      private

      FILTER_PREFIX = "by_".freeze
      FILTER_SUFFIX = "!".freeze

      # Splits the kwargs into an array of Items and a hash of filters + their argument.
      # @param kwargs [Hash] must include :items [Array<Item>] and one or more
      #   of the filters defined in by_x methods below.
      # @return [Array(Hash, Array<Item>, Boolean)]
      # @raise [ArgumentError] if kwargs are invalid or missing.
      def split_kwargs(kwargs)
        unless kwargs.has_key?(:items)
          raise ArgumentError, "Filter::by requires an :items keyword argument."
        end

        given_filters = kwargs.except(:items, :no_sort).keys
        if given_filters.none?
          raise ArgumentError, "Filter::by requires at least one of these filters"
        end

        available_filters = private_methods(false)
          .select { _1.to_s.start_with?(FILTER_PREFIX) }
          .map { _1.to_s.delete_prefix(FILTER_PREFIX).delete_suffix(FILTER_SUFFIX).to_sym }
        unrecognized_filters = given_filters - available_filters
        if unrecognized_filters.any?
          raise ArgumentError, "Unrecognized filter args passed to Filter::by: #{unrecognized_filters}"
        end

        items = kwargs.fetch(:items)
        no_sort = kwargs[:no_sort]
        filters_and_args = kwargs.except(:items, :no_sort)

        [filters_and_args, items, no_sort]
      end

      # Mutates the given array of Items to select only Items with a rating
      # greater than or equal to the given minimum.
      # @param items [Array<Item>]
      # @param minimum_rating [Integer]
      def by_minimum_rating!(items, minimum_rating)
        return items unless minimum_rating

        items.select! do |item|
          if item.rating
            item.rating >= minimum_rating
          end
        end
      end

      # Mutates the given array of Items to exclude Items with genres including
      # any of the given genres.
      # @param items [Array<Item>]
      # @param excluded_genres [Array<String>]
      def by_excluded_genres!(items, excluded_genres)
        return items unless excluded_genres&.any?

        items.select! do |item|
          overlapping = item.genres & excluded_genres
          overlapping.empty?
        end
      end

      # Mutates the given array of Items to select only Items with a status
      # equal to the given status (or one of the given statuses).
      # @param items [Array<Item>]
      # @param statuses [Symbol, Array<Symbol>]
      def by_status!(items, statuses)
        statuses = Array(statuses)

        items.select! do |item|
          statuses.include? item.status
        end
      end
    end
  end
end
