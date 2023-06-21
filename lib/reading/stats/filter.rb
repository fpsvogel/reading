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

      # Each action filters the given Items.
      # @param operator [Symbol] e.g. the method representing the operator,
      #   usually simply the operator string converted to a symbol, e.g.
      #   :">=" from "rating>=2"; but in some cases the method is alphabetic,
      #   e.g. :include? from "source~library".
      # @param values [Array<String>] the values after the operator, split by
      #   commas.
      # @param items [Array<Item>]
      # @return [Array<Item>] a subset of the given Items.
      ACTIONS = {
        rating: proc { |values, operator, items|
          ratings = values.map { |value|
            Integer(value, exception: false) ||
              Float(value, exception: false) ||
              (raise InputError, "Rating must be a number in \"rating#{operator}#{value}\"")
          }

          positive_operator = operator == :'!=' ? :== : operator

          matches = items.filter { |item|
            ratings.any? { |rating|
              item.rating.send(positive_operator, rating) if item.rating
            }
          }

          # Instead of using item.rating.send(operator, format) above, invert
          # the matches here so that the not-equal operator with multiple values
          # means "not x and not y". The other way would mean "not x or not y".
          if operator == :'!='
            matches = items - matches
          end

          matches
        },
        format: proc { |values, operator, items|
          formats = values.map(&:to_sym)

          matches = items.filter { |item|
            formats.any? { |format|
              item.variants.any? { _1.format == format }
            }
          }

          if operator == :'!='
            matches = items - matches
          end

          remove_nonmatching_variants(matches) do |variant|
            formats.any? { variant.format.send(operator, _1) }
          end

          matches
        },
        author: proc { |values, operator, items|
          fragments = values
            .map(&:downcase)
            .map { _1.gsub(/[^a-zA-Z ]/, '').gsub(/\s/, '') }

          matches = items.filter { |item|
            next unless item.author

            author = item
              .author
              .downcase
              .gsub(/[^a-zA-Z ]/, '')
              .gsub(/\s/, '')

            if %i[include? exclude?].include? operator
              fragments.any? { author.include? _1 }
            else
              fragments.any? { author == _1 }
            end
          }

          if %i[!= exclude?].include? operator
            matches = items - matches
          end

          matches
        },
        title: proc { |values, operator, items|
          fragments = values
            .map(&:downcase)
            .map { _1.gsub(/[^a-zA-Z0-9 ]|\ba\b|\bthe\b/, '').gsub(/\s/, '') }

          matches = items.filter { |item|
            next unless item.title

            title = item
              .title
              .downcase
              .gsub(/[^a-zA-Z0-9 ]|\ba\b|\bthe\b/, '')
              .gsub(/\s/, '')

            if %i[include? exclude?].include? operator
              fragments.any? { title.include? _1 }
            else
              fragments.any? { title == _1 }
            end
          }

          if %i[!= exclude?].include? operator
            matches = items - matches
          end

          matches
        },
        series: proc { |values, operator, items|
          fragments = values
            .map(&:downcase)
            .map { _1.gsub(/[^a-zA-Z0-9 ]|\ba\b|\bthe\b/, '').gsub(/\s/, '') }

          matches = items.filter { |item|
            item.variants.any? { |variant|
              variant.series.any? { |series|
                series_name = series
                  .name
                  .downcase
                  .gsub(/[^a-zA-Z0-9 ]|\ba\b|\bthe\b/, '')
                  .gsub(/\s/, '')

                if %i[include? exclude?].include? operator
                  fragments.any? { series_name.include? _1 }
                else
                  fragments.any? { series_name == _1 }
                end
              }
            }
          }

          if %i[!= exclude?].include? operator
            matches = items - matches
          end

          matches
        },
        source: proc { |values, operator, items|
          fragments = values.map(&:downcase)

          matches = items.filter { |item|
            item.variants.any? { |variant|
              names_and_urls = (variant.sources.map(&:name) + variant.sources.map(&:url)).compact

              names_and_urls.map(&:downcase).any? { |name_or_url|
                if %i[include? exclude?].include? operator
                  fragments.any? { name_or_url.downcase.include? _1 }
                else
                  fragments.any? { name_or_url.downcase == _1 }
                end
              }
            }
          }

          if %i[!= exclude?].include? operator
            matches = items - matches
          end

          remove_nonmatching_variants(matches) do |variant|
            names_and_urls = (variant.sources.map(&:name) + variant.sources.map(&:url)).compact

            names_and_urls.any? { |name_or_url|
              fragments.any? { name_or_url.downcase.send(operator, _1) }
            }
          end

          matches
        },
        status: proc { |values, operator, items|
          statuses = values.map { _1.squeeze(' ').gsub(' ', '_').to_sym }

          matches = items.filter { |item|
            statuses.include? item.status
          }

          if operator == :'!='
            matches = items - matches
          end

          matches
        },
        genre: proc { |values, operator, items|
          genres = values.map { _1.split('+').map(&:strip) }

          matches = items.filter { |item|
            genres.any? { |and_genres|
              # Whether item.genres includes all elements of and_genres.
              (item.genres.sort & and_genres.sort) == and_genres.sort
            }
          }

          if operator == :'!='
            matches = items - matches
          end

          matches
        },
        length: proc { |values, operator, items|
          lengths = values.map { |value|
            Integer(value, exception: false) ||
              Item::TimeLength.parse(
                value,
                # TODO: somehow provide the user with control over the pages per hour.
                pages_per_hour: Reading.default_config.fetch(:pages_per_hour),
              ) ||
              (raise InputError, "Length must be a number of pages or " \
                "time as hh:mm in \"length#{operator}#{value}\"")
          }

          positive_operator = operator == :'!=' ? :== : operator

          matches = items.filter { |item|
            lengths.any? { |length|
              item.variants.any? { _1.length.send(positive_operator, length) }
            }
          }

          if operator == :'!='
            matches = items - matches
          end

          remove_nonmatching_variants(matches) do |variant|
            lengths.any? { variant.length.send(operator, _1) }
          end

          matches
        },
        note: proc { |values, operator, items|
          fragments = values
            .map(&:downcase)
            .map { _1.gsub(/[^a-zA-Z0-9 ]/, '') }

          matches = items.filter { |item|
            item.notes.any? { |original_note|
              note = original_note
                .downcase
                .gsub(/[^a-zA-Z0-9 ]/, '')

              if %i[include? exclude?].include? operator
                fragments.any? { note.include? _1 }
              else
                fragments.any? { note == _1 }
              end
            }
          }

          if %i[!= exclude?].include? operator
            matches = items - matches
          end

          matches
        },
      }

      NUMERIC_OPERATORS = {
        rating: true,
        length: true,
        progress: true,
      }

      PROHIBIT_INCLUDE_EXCLUDE_OPERATORS = {
        genre: true,
        format: true,
        status: true,
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
      # @return [Array<Item>] a subset of the given Items.
      private_class_method def self.filter_single(key, predicate, operator_str, items)
        filtered_items = []

        if NUMERIC_OPERATORS[key]
          allowed_operators = %w[= != > >= < <=]
        elsif PROHIBIT_INCLUDE_EXCLUDE_OPERATORS[key]
          allowed_operators = %w[= !=]
        else
          allowed_operators = %w[= != ~ !~]
        end

        unless allowed_operators.include? operator_str
          raise InputError, "Operator \"#{operator_str}\" not allowed in the " \
            "#{key} filter. Allowed: #{allowed_operators.join(', ')}"
        end

        operator = operator_str.to_sym
        operator = :== if operator == :'='
        operator = :include? if operator == :~
        operator = :exclude? if operator == :'!~'

        or_values = predicate.split(',').map(&:strip)

        matched_items = ACTIONS[key].call(or_values, operator, items)
        # debugger if key == :source && operator_str == '!~' && predicate == 'library,archive'
        filtered_items += matched_items

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
