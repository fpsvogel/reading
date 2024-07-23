module Reading
  module Stats
    # The part of the query right after the operation, which groups the results,
    # e.g. "by genre, rating".
    class Grouping
      # Determines which group(s) the input indicates, and then groups the
      # Items accordingly. For the groups and their actions, see the constants
      # below.
      # @param input [String] the query string.
      # @param items [Array<Item>] the Items on which to run the operation.
      # @return [Hash] the return value of the group action(s).
      def self.group(input, items)
        grouped_items = {}

        match = input.match(REGEX)

        if match
          group_names = match[:groups]
            .split(',')
            .tap { _1.last.sub!(/(\w)\s+\w+/, '\1') }
            .map(&:strip)
            .map { _1.delete_suffix('s') }
            .map(&:to_sym)

          if group_names.uniq.count < group_names.count
            raise InputError, "Each grouping can be applied only once in a query."
          end

          begin
            return group_hash(items, group_names)
          rescue InputError => e
            raise e.class, "#{e.message} in \"#{input}\""
          end
        end

        { all: items }
      end

      # Recursively builds a tree of groupings based on group_names.
      # @group_names [Array<Symbol>]
      # @items [Array<Item>]
      # @return [Hash, Array<Item>]
      private_class_method def self.group_hash(items, group_names)
        return items if group_names.empty?

        key = group_names.first
        action = ACTIONS[key]

        unless action
          raise InputError, "Invalid grouping \"#{key}\""
        end

        action.call(items).transform_values do |grouped_items|
          group_hash(grouped_items, group_names[1..])
        end
      end

      private

      INPUT_SPLIT = /\s+(?=[\w\-]+\s*(?:!=|=|!~|~|>=|>|<=|<))/

      # Each action groups the given Items.
      # @param items [Array<Item>]
      # @return [Hash{Symbol => Array<Item>}] the Items separated into groups.
      ACTIONS = {
        rating: proc { |items|
          items
            .group_by(&:rating)
            .reject { |rating, _items| rating.nil? }
            .sort_by { |rating, _items| rating }
            .reverse
            .to_h
        },
        format: proc { |items|
          groups = Hash.new { |h, k| h[k] = [] }

          items.each do |item|
            item.variants.group_by(&:format).each do |format, variants|
              groups[format] << item.with_variants(variants)
            end
          end

          groups.sort.to_h
        },
        source: proc { |items|
          groups = Hash.new { |h, k| h[k] = [] }

          items.each do |item|
            item
              .variants
              .map { |variant|
                variant.sources.map { |source|
                  [variant, source.name || source.url]
                }
              }
              .flatten(1)
              .group_by { |_variant, source| source }
              .transform_values { |variants_and_sources|
                variants_and_sources.map(&:first)
              }
              .each do |source, variants|
                groups[source] << item.with_variants(variants)
              end
          end

          groups.sort.to_h
        },
        year: proc { |items|
          begin_date = items
            .map { _1.experiences.first&.spans&.first&.dates&.begin }
            .compact
            .min

          if begin_date.nil?
            {}
          else
            end_date = items
              .flat_map { _1.experiences.map(&:last_end_date) }
              .compact
              .max

            end_year = [Date.today.year, end_date.year].min

            year_ranges = (begin_date.year..end_year).flat_map { |year|
              beginning_of_year = Date.new(year, 1, 1)
              end_of_year = Date.new(year + 1, 1, 1).prev_day

              beginning_of_year..end_of_year
            }

            groups = year_ranges.map { [_1, []] }.to_h

            groups.each do |year_range, year_items|
              items.each do |item|
                without_before = item.split(year_range.end.next_day).first
                without_before_or_after = without_before&.split(year_range.begin)&.last

                year_items << without_before_or_after if without_before_or_after
              end
            end

            groups.transform_keys! { |year_range|
              year_range.begin.year
            }

            groups
          end
        },
        month: proc { |items|
          begin_date = items
            .map { _1.experiences.first&.spans&.first&.dates&.begin }
            .compact
            .min

          if begin_date.nil?
            {}
          else
            end_date = items
              .flat_map { _1.experiences.map(&:last_end_date) }
              .compact
              .max

            month_ranges = (begin_date.year..end_date.year).flat_map { |year|
              (1..12).map { |month|
                beginning_of_month = Date.new(year, month, 1)

                end_of_month =
                  if month == 12
                    Date.new(year + 1, 1, 1).prev_day
                  else
                    Date.new(year, month + 1, 1).prev_day
                  end

                beginning_of_month..end_of_month
              }
            }

            groups = month_ranges.map { [_1, []] }.to_h

            groups.each do |month_range, month_items|
              items.each do |item|
                without_before = item.split(month_range.end.next_day).first
                without_before_or_after = without_before&.split(month_range.begin)&.last

                month_items << without_before_or_after if without_before_or_after
              end
            end

            groups.transform_keys! { |month_range|
              [month_range.begin.year, month_range.begin.month]
            }

            groups
          end
        },
        genre: proc { |items|
          groups = Hash.new { |h, k| h[k] = [] }

          items.each do |item|
            if item.genres.any?
              genre_combination = item.genres.sort.join(", ")
              groups[genre_combination] << item
            end
          end

          groups.sort.to_h
        },
        length: proc { |items|
          boundaries = Config.hash.fetch(:length_group_boundaries)

          groups = boundaries.each_cons(2).map { |a, b|
            [a..b, []]
          }

          groups.unshift([0..boundaries.first, []])
          groups << [boundaries.last.., []]

          groups = groups.to_h

          items.each do |item|
            item
              .variants
              .map { |variant| [variant, variant.length] }
              .group_by { |_variant, length|
                groups.keys.find { |length_range| length_range.include?(length) }
              }
              .transform_values { |variants_and_lengths|
                variants_and_lengths.map(&:first)
              }
              .reject { |length_range, _variants| length_range.nil? }
              .each do |length_range, variants|
                groups[length_range] << item.with_variants(variants)
              end
          end

          groups
        },
      }

      REGEX = %r{\A
        [^=]+ # the operation
        by
        \s*
        (?<groups>[\w,\s]+)
      }x
    end
  end
end
