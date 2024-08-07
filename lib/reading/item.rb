require "forwardable"

require_relative "item/view"

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
    # @param view [Class, nil, Boolean] the class that will be used to build the
    #   view object, or nil/false if no view object should be built. If you use
    #   a custom view class, the only requirement is that its #initialize take
    #   an Item.
    def initialize(item_hash_or_data, view: Item::View)
      if item_hash_or_data.is_a? Data
        @data = item_hash_or_data
      elsif item_hash_or_data.is_a? Hash
        item_hash = item_hash_or_data.dup

        add_missing_attributes_with_filler_values!(item_hash)
        add_statuses_and_last_end_dates!(item_hash)

        @data = item_hash.to_data
      end

      @view = view.new(self) if view
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
        updated_variant_indices[old_index] = new_index if new_index
      }

      # Remove experiences associated with the removed variants.
      kept_experiences = (new_experiences || experiences).select { |experience|
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

    # Splits this Item into two Items: one < the given date, and the other >= it.
    # @date [Date] must be the first day of a month.
    # @return [Array(Item, Item)]
    def split(date)
      before_index = nil
      middle_indices = experiences.map.with_index { |experience, i|
        if experience.spans.first.dates &&
          experience.spans.first.dates.begin < date

          before_index = i

          if (experience.last_end_date || Date.today) >= date
            i
          else
            nil
          end
        end
      }
      .compact

      # There are no experiences with spans that overlap the date.
      if middle_indices.none?
        # The Item is planned.
        return [] if experiences.none? { _1.spans.first.dates }
        # date is after all spans.
        return [self, nil] if experiences.all? { _1.last_end_date && date > _1.last_end_date }
        # date is before all spans.
        return [nil, self] if experiences.all? { _1.spans.first.dates.begin >= date }

        # Date is in between experiences.
        if before_index
          item_before = with_experiences(experiences[..before_index])
          item_after = with_experiences(experiences[(before_index + 1)..])

          return [item_before, item_after]
        end
      end

      if middle_indices.first == 0
        experiences_before = []
      else
        experiences_before = experiences[..(middle_indices.first - 1)]
      end
      experiences_after = experiences[(middle_indices.first + middle_indices.count)..]
      experiences_middle = experiences.values_at(*middle_indices)

      # TODO remove this check?
      unless middle_indices == (middle_indices.min..middle_indices.max).to_a
        raise Reading::Error, "Non-consecutive experiences found during Item#split."
      end

      experiences_middle.each do |experience_middle|
        before_index = nil
        span_middle_index = experience_middle
          .spans
          .index.with_index { |span, i|
            if span.dates && span.dates.begin < date
              before_index = i

              (span.dates.end || Date.today) >= date
            end
          }

        if span_middle_index.nil? # date is between spans.
          spans_before = experience_middle.spans[..before_index]
          spans_after = experience_middle.spans[(before_index + 1)..]
        else
          span_middle = experience_middle.spans[span_middle_index]

          unless span_middle.dates.end
            end_today_instead_of_endless = { dates: span_middle.dates.begin..Date.today }
            span_middle = span_middle.to_h.merge(end_today_instead_of_endless).to_data
          end

          dates_before = span_middle.dates.begin..date.prev_day
          amount_before = (span_middle.amount || 0) * (dates_before.count / span_middle.dates.count.to_f)
          span_middle_before = span_middle.with(
            dates: dates_before,
            amount: amount_before,
          )

          dates_after = date..span_middle.dates.end
          amount_after = (span_middle.amount || 0) * (dates_after.count / span_middle.dates.count.to_f)
          span_middle_after = span_middle.with(
            dates: dates_after,
            amount: amount_after,
          )

          if span_middle_index.zero?
            spans_before = [span_middle_before]
          else
            spans_before = [
              *experience_middle.spans[..(span_middle_index - 1)],
              span_middle_before,
            ]
          end

          spans_after = [
            span_middle_after,
            *experience_middle.spans[(span_middle_index + 1)..],
          ]
        end

        experience_middle_before = experience_middle.with(
          spans: spans_before,
          last_end_date: spans_before.map { _1.dates&.end }.compact.last,
        )
        experience_middle_after = experience_middle.with(
          spans: spans_after,
        )

        experiences_before << experience_middle_before
        experiences_after.unshift(*experience_middle_after)
      end

      # RM (alternate implementation)
      # experiences_before = experiences
      #   .select(&:last_end_date)
      #   .select { _1.last_end_date < date }
      # experiences_after = experiences
      #   .select { _1.spans.first.dates.nil? || _1.spans.first.dates.begin >= date }

      # experiences_middle = experiences.select {
      #   _1.spans.first.dates.begin < date && _1.last_end_date >= date
      # }
      # experiences_middle.each do |experience_middle|
      #   spans_before = experience_middle
      #     .spans
      #     .select { _1.dates&.end }
      #     .select { _1.dates.end < date }
      #   spans_after = experience_middle
      #     .spans
      #     .select(&:dates)
      #     .select { _1.dates.begin >= date }

      #   span_middle = experience_middle
      #     .spans
      #     .find { _1.dates && _1.dates.begin < date && _1.dates.end >= date }

      #   middle_index = experience_middle.spans.index(span_middle)
      #   planned_spans_before = experience_middle
      #     .spans
      #     .map.with_index { |span, i|
      #       [i, span] if span.dates.nil? && i < middle_index
      #     }
      #     .compact
      #   planned_spans_after = experience_middle
      #     .spans
      #     .map.with_index { |span, i|
      #       [i, span] if span.dates.nil? && i > middle_index
      #     }
      #     .compact

      #   if span_middle
      #     dates_before = span_middle.dates.begin..date.prev_day
      #     amount_before = span_middle.amount * (dates_before.count / span_middle.dates.count.to_f)
      #     span_middle_before = span_middle.with(
      #       dates: dates_before,
      #       amount: amount_before,
      #     )

      #     dates_after = date..span_middle.dates.end
      #     amount_after = span_middle.amount * (dates_after.count / span_middle.dates.count.to_f)
      #     span_middle_after = span_middle.with(
      #       dates: dates_after,
      #       amount: amount_after,
      #     )

      #     spans_before = [*spans_before, span_middle_before]
      #     spans_after = [span_middle_after, *spans_after]

      #     planned_spans_before.each do |i, planned_span|
      #       spans_before.insert(i, planned_span)
      #     end
      #     planned_spans_after.each do |i, planned_span|
      #       spans_after.insert(i - middle_index, planned_span)
      #     end
      #   end

      #   experience_middle_before = experience_middle.with(
      #     spans: spans_before,
      #     last_end_date: spans_before.last.dates.end,
      #   )
      #   experience_middle_after = experience_middle.with(
      #     spans: spans_after,
      #   )

      #   experiences_before << experience_middle_before
      #   experiences_after = [experience_middle_after, *experiences_after]
      # end

      item_before = with_experiences(experiences_before)
      item_after = with_experiences(experiences_after)

      [item_before, item_after]
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

    # For each missing item attribute (key in Config.hash[:item][:template]) in
    # item_hash, adds the key and a filler value.
    # @param item_hash [Hash]
    def add_missing_attributes_with_filler_values!(item_hash)
      Config.hash.deep_fetch(:item, :template).each do |k, v|
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
    # @return [Array(Symbol, Date)]
    def add_statuses_and_last_end_dates!(item_hash)
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
          grace_period = Config.hash.deep_fetch(
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
