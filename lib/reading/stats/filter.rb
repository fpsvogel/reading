module Reading
  module Stats
    # The parts of a query that filter the data being queried, e.g. "genre=history".
    class Filter
      # Determines which filters are contained in the given input, and then runs
      # them to get the remaining Items. For the filters and their actions, see
      # the constants below.
      # @param input [String] the query string.
      # @param items [Array<Item>] the Items on which to run the operation.
      # @return [Object] the return value of the action.
      def self.filter(input, items)
        filtered_items = nil

        split_input = input.split(INPUT_SPLIT)

        split_input[1..-1].each do |filter_input|
          match_found = false

          REGEXES.each do |key, regex|
            match = filter_input.match(regex)

            if match
              filtered_items ||= []
              filtered_items += ACTIONS[key].call(items, match[:value], match[:operator])
              match_found = true
            end
          end

          unless match_found
            raise InputError, "Invalid filter \"#{filter_input}\""
          end
        end

        filtered_items || items
      end

      private

      INPUT_SPLIT = /\s+(?=\w+\s*=|>|>=|<|<=)/

      ACTIONS = {
        genre: proc { |items, value|
          filtered_items = []

          or_genres = value.split(',').map(&:strip)

          or_genres.each do |genres|
            and_genres = genres.split('+').map(&:strip)
            matched_items = items.filter { |item|
              # Whether item.genres includes all elements of and_genres.
              item.genres.sort & and_genres.sort == and_genres.sort
            }

            filtered_items += matched_items
          end

          filtered_items
        },
      }

      REGEXES = ACTIONS.map { |key, _action|
        regex =
          %r{\A
            \s*
            #{key}
            e?s?
            (?<operator>=|>|>=|<|<=)
            (?<value>.+)
          \z}x

        [key, regex]
      }.to_h
    end
  end
end
