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
        filtered_items = items

        split_input = input.split(INPUT_SPLIT)

        split_input[1..-1].each do |filter_input|
          match_found = false

          REGEXES.each do |key, regex|
            match = filter_input.match(regex)

            if match
              match_found = true

              filtered_items = filter_single(key, match[:predicate], match[:operator], filtered_items)
            end
          end

          unless match_found
            raise InputError, "Invalid filter \"#{filter_input}\""
          end
        end

        filtered_items
      end

      private

      INPUT_SPLIT = /\s+(?=\w+\s*(?:!=|=|!~|~|>=|>|<=|<))/

      ACTIONS = {
        rating: proc { |value, operator, items|
          rating = Integer(value, exception: false) ||
            Float(value, exception: false) ||
            (raise InputError, "Rating must be a number in \"rating#{operator}#{value}\"")

          items.filter { |item|
            item.rating.send(operator, rating)
          }
        },
        format: proc { |value, operator, items|
          format = value.to_sym

          matches = items.filter { |item|
            item.variants.any? { _1.format == format }
          }

          # Invert the matches instead of _1.format.send(operator, format) in the
          # filter because that would exclude items without a format.
          if operator == '!='.to_sym
            matches = items - matches
          end

          remove_nonmatching_variants(matches) do |variant|
            variant.format.send(operator, format)
          end

          matches
        },
        source: proc { |value, operator, items|
          matches = items.filter { |item|
            item.variants.any? { |variant|
              names_and_urls = (variant.sources.map(&:name) + variant.sources.map(&:url)).compact

              names_and_urls.map(&:downcase).any? {
                if %i[include? exclude?].include? operator
                  _1.downcase.include? value
                else
                  _1 == value.downcase
                end
              }
            }
          }

          if %i[!= exclude?].include? operator
            matches = items - matches
          end

          remove_nonmatching_variants(matches) do |variant|
            names_and_urls = (variant.sources.map(&:name) + variant.sources.map(&:url)).compact

            names_and_urls.any? { _1.downcase.send(operator, value.downcase) }
          end

          matches
        },
        genre: proc { |value, operator, items|
          and_genres = value.split('+').map(&:strip)

          matches = items.filter { |item|
            # Whether item.genres includes all elements of and_genres.
            (item.genres.sort & and_genres.sort) == and_genres.sort
          }

          if operator == '!='.to_sym
            matches = items - matches
          end

          matches
        },
      }

      ALLOW_NUMERIC_OPERATORS = {
        rating: true,
        length: true,
        progress: true,
      }

      REGEXES = ACTIONS.map { |key, _action|
        regex =
          %r{\A
            \s*
            #{key}
            e?s?
            (?<operator>!=|=|!~|~|>=|>|<=|<)
            (?<predicate>.+)
          \z}x

        [key, regex]
      }.to_h

      # Applies a single filter to an array of Items.
      # @param key [Symbol] the filter's key in the constants above.
      # @param predicate [String] the input value(s) after the operator.
      # @param operator_str [String] from the input.
      # @param items [Array<Item>]
      # @return [Array<Item>]
      private_class_method def self.filter_single(key, predicate, operator_str, items)
        filtered_items = []

        if ALLOW_NUMERIC_OPERATORS[key]
          allowed_operators = %w[= != > >= < <=]
        else
          allowed_operators = %w[= != ~ !~]
        end

        unless allowed_operators.include? operator_str
          raise InputError, "Operator \"#{operator_str}\" not allowed in the " \
            "#{key} filter. Allowed: #{allowed_operators.join(', ')}"
        end

        operator = operator_str.to_sym
        operator = :== if operator == '='.to_sym
        operator = :include? if operator == :~
        operator = :exclude? if operator == '!~'.to_sym

        or_values = predicate.split(',').map(&:strip)

        or_values.each do |value|
          matched_items = ACTIONS[key].call(value, operator, items)
          # debugger if key == :source && operator_str == '!~' && predicate == 'library,archive'

          filtered_items += matched_items
        end

        filtered_items.uniq
      end

      private_class_method def self.remove_nonmatching_variants(items)
        items.each do |item|
          kept_variant_indices = []

          # Within each item, remove variants that do not match.
          item.variants.filter!.with_index { |variant, index|
            yield(variant) && kept_variant_indices << index
          }

          # Also remove experiences associated with the removed variants.
          item.experiences.filter! { |experience|
            kept_variant_indices.include?(experience.variant_index)
          }

          # Then update the variant indices.
          item.experiences.map! { |experience|
            shifted_variant_index = kept_variant_indices.index(experience.variant_index)
            experience.with(variant_index: shifted_variant_index)
          }
        end
      end
    end
  end
end
