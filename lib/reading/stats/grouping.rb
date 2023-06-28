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
        genre: proc { |items|
          groups = Hash.new { |h, k| h[k] = [] }

          items.each do |item|
            item.genres.each { |genre| groups[genre] << item }
          end

          groups.sort
        },
        length: proc { |items|
          groups = Hash.new { |h, k| h[k] = [] }

          items.each do |item|
            item.variants.map(&:length).each { |length| groups[length] << item }
          end

          groups.sort
        },
      }

      REGEX = %r{\A
        [^=]+ # the operation
        by
        \s+
        (?<group>\w+)
      }x
    end
  end
end
