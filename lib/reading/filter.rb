module Reading
  # Filters Items based on given criteria.
  class Filter
    class << self
      # Filters Items based on given criteria, and returns them sorted by last
      # end date or (where there is none) status, where :planned Items are
      # placed last, and :in_progress just before those.
      # @param items [Array<Item>]
      # @param no_sort [Boolean] to preserve the original ordering of the Items.
      # @param criteria [Hash] one or more of the filters defined in by_x methods below.
      # @return [Array<Item>]
      # @raise [ArgumentError] if criteria are invalid or missing.
      def by(items:, no_sort: false, **criteria)
        validate_criteria(**criteria)

        filtered = criteria.each.with_object(items.dup) { |(criterion, arg), filtered_items|
          send("#{CRITERIA_PREFIX}#{criterion}#{CRITERIA_SUFFIX}", filtered_items, arg)
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

      CRITERIA_PREFIX = "by_".freeze
      CRITERIA_SUFFIX = "!".freeze

      # Checks that the args match real Filter criteria.
      # @param criteria [Hash] must include only one or more of the criteria
      #   defined in by_x methods below.
      # @raise [ArgumentError] if criteria are empty or invalid.
      def validate_criteria(**criteria)
        available_criteria = private_methods(false)
          .select { _1.to_s.start_with?(CRITERIA_PREFIX) }
          .map { _1.to_s.delete_prefix(CRITERIA_PREFIX).delete_suffix(CRITERIA_SUFFIX).to_sym }

        if criteria.empty?
          raise ArgumentError, "Filter requires at least one of these criteria: #{available_criteria}"
        end

        unrecognized_criteria = criteria.keys - available_criteria
        if unrecognized_criteria.any?
          raise ArgumentError, "Unrecognized criteria passed to Filter: #{unrecognized_criteria}"
        end
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
