module Reading
  module Stats
    # The first part of a query.
    class Operation
      # The default number argument if one is not given, as in "top ratings"
      # rather than "top 5 ratings".
      DEFAULT_NUMBER_ARG = 10

      # Determines which type of operation is contained in the given input, and
      # then runs it to get the result. For the types of operations and their
      # actions, see the constants below.
      # @param input [String] the query string.
      # @param items [Array<Item>] the Items on which to run the operation.
      # @return [Object] the return value of the action.
      def self.execute(input, items)
        REGEXES.each do |key, regex|
          match = input.match(regex)

          if match
            if match[:number_arg]
              number_arg = Integer(match[:number_arg], exception: false) ||
                (raise InputError, "Argument must be an integer. Example: top 5 ratings")
            end

            result = ACTIONS[key].call(items, number_arg)
            return result
          end
        end

        raise InputError, "Stats input could not be matched to a valid operation."
      end

      private

      ACTIONS = {
        average_rating: proc { |items|
          ratings = items.map(&:rating).compact
          ratings.sum.to_f / ratings.count
        },
        average_length: proc { |items|
          items.flat_map { |item|
            item.experiences.map { |experience|
              item.variants[experience.variant_index].length
            }
          }.compact.sum / items.count
        },
        average_amount: proc { |items|
        },
        count: proc { |items|
          items.count
        },
        top_rating: proc { |items, number_arg|
          items
            .max_by(number_arg || DEFAULT_NUMBER_ARG, &:rating)
            .map { |item| [item.title, item.rating] }
        },
        top_length: proc { |items, number_arg|
          items
            .max_by(number_arg || DEFAULT_NUMBER_ARG) { |item|
              item.variants.map(&:length).max
            }
            .map { |item| [item.title, item.variants.map(&:length).max] }
        },
      }

      REGEXES = ACTIONS.map { |key, _action|
        first_word, second_word = key.to_s.split('_')

        regex =
          %r{\A
            \s*
            #{first_word}
            \s*
            (?<number_arg>
              \d+
            )?
            \s*
            #{second_word}
            s?
            \s*
          \z}x

        [key, regex]
      }.to_h
    end
  end
end
