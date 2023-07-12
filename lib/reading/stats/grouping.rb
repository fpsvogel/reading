module Reading
  module Stats
    # The part of the query right after the operation, which groups the results,
    # e.g. "by genre".
    class Grouping
      # Determines which group is indicated in the given input, and then groups
      # the Items accordingly. For the groups and their actions, see the
      # constants below.
      # @param input [String] the query string.
      # @param items [Array<Item>] the Items on which to run the operation.
      # @return [Object] the return value of the action.
      def self.group(input, items)
        grouped_items = {}

        match = input.match(REGEX)

        if match
          group_name = match[:group].delete_suffix('s')
          action = ACTIONS[group_name.to_sym]

          unless action
            raise InputError, "Invalid grouping \"#{group_name}\" in \"#{input}\""
          end

          return action.call(items)
        end

        { all: items }
      end

      private

      INPUT_SPLIT = /\s+(?=[\w\-]+\s*(?:!=|=|!~|~|>=|>|<=|<))/

      # Each action groups the given Items.
      # @param items [Array<Item>]
      # @return [Hash{Symbol => Array<Item>}] the Items separated into groups.
      ACTIONS = {
        rating: proc { |items|
          items.group_by { |item|
            item.rating
          }
          .sort
        },
        format: proc { |items|
          groups = Hash.new { |h, k| h[k] = [] }

          items.each do |item|
            item.variants.map(&:format).each { |format| groups[format] << item }
          end

          groups.sort
        },
        source: proc { |items|
          groups = Hash.new { |h, k| h[k] = [] }

          items.each do |item|
            item.variants.flat_map { |variant|
              variant.sources.map { |source|
                source.name || source.url
              }
            }
            .each { |source| groups[source] << item }
          end

          groups.sort
        },
        year: proc { |items|
          begin_date = items.first.experiences.first.spans.first.dates.begin

          end_date = items
            .flat_map { _1.experiences.map(&:last_end_date) }
            .compact
            .sort
            .last

          year_ranges = (begin_date.year..end_date.year).flat_map { |year|
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
        },
        month: proc { |items|
          begin_date = items.first.experiences.first.spans.first.dates.begin

          end_date = items
            .flat_map { _1.experiences.map(&:last_end_date) }
            .compact
            .sort
            .last

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
        },
        genre: proc { |items|
          groups = Hash.new { |h, k| h[k] = [] }

          items.each do |item|
            item.genres.each { |genre| groups[genre] << item }
          end

          groups.sort
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
            item.variants.map(&:length).each { |length|
              groups.each do |length_range, items_of_length|
                if length_range.include?(length)
                  items_of_length << item unless items_of_length.include?(item)
                  break
                end
              end
            }
          end

          groups
        },
      }

      REGEX = %r{\A
        [^=]+ # the operation
        by
        \s*
        (?<group>\w+)
      }x
    end
  end
end
