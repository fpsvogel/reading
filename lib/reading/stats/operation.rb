require "bigdecimal/util"

module Reading
  module Stats
    # The beginning of a query which specifies what it does, e.g.
    # "average rating" or "total amount".
    class Operation
      using Util::NumericToIIfWhole

      # Determines which operation is contained in the given input, and then
      # runs it to get the result. For the operations and their actions, see
      # the constants below.
      # @param input [String] the query string.
      # @param grouped_items [Hash{Symbol => Array<Item>}] if no group was used,
      #   the hash is just { all: items }
      # @param result_formatters [Hash{Symbol => Proc}] to alter the appearance
      #   of results. Keys should be from among the keys of Operation::ACTIONS.
      # @return [Object] the return value of the action; if items are grouped
      #   then a hash is returned with the same keys as grouped_items, otherwise
      #   just the array of all results (not grouped) is returned.
      def self.execute(input, grouped_items, result_formatters)
        REGEXES.each do |key, regex|
          match = input.match(regex)

          if match
            if match[:number_arg]
              number_arg = Integer(match[:number_arg], exception: false) ||
                (raise InputError, "Argument must be an integer. Example: top 5 ratings")
            end

            results = apply_to_inner_items(grouped_items) do |inner_items|
              result = ACTIONS[key].call(inner_items, number_arg)

              default_formatter = :itself.to_proc # just the result itself
              result_formatter = result_formatters[key] || default_formatter

              result_formatter.call(result)
            end

            if results.keys == [:all] # no groupings
              return results[:all]
            else
              return results
            end
          end
        end

        raise InputError, "No valid operation in stats query \"#{input}\""
      end

      # A recursive method that applies the block to the leaf nodes (arrays of
      # Items) of the given hash of grouped items.
      # @param grouped_items [Hash]
      # @yield [Array<Item>]
      def self.apply_to_inner_items(grouped_items, &block)
        if grouped_items.values.first.is_a? Array
          grouped_items.transform_values! { |inner_items|
            yield inner_items
          }
        else # It's a Hash, so go one level deeper.
          grouped_items.each do |group_name, grouped|
            apply_to_inner_items(grouped, &block)
          end
        end
      end

      private

      # The default number argument if one is not given, as in "top ratings"
      # rather than "top 5 ratings".
      DEFAULT_NUMBER_ARG = 10

      # Each action makes some calculation based on the given Items.
      # @param items [Array<Item>]
      # @return [Object] in most cases an Integer.
      ACTIONS = {
        average_rating: proc { |items|
          ratings = items.map(&:rating).compact

          if ratings.any?
            (ratings.sum.to_f / ratings.count).to_i_if_whole
          end
        },
        average_length: proc { |items|
          lengths = items.flat_map { |item|
            item.variants.map(&:length)
          }
          .compact

          if lengths.any?
            (lengths.sum / lengths.count.to_f).to_i_if_whole
          end
        },
        average_amount: proc { |items|
          total_amount = items.sum { |item|
            item.experiences.sum { |experience|
              experience.spans.sum(&:amount)
            }
          }

          (total_amount / items.count.to_f).to_i_if_whole
        },
        :"average_daily-amount" => proc { |items|
          amounts_by_date = calculate_amounts_by_date(items)

          if amounts_by_date.any?
            amounts_by_date.values.sum / amounts_by_date.count
          end
        },
        list_item: proc { |items|
          items.map { |item| author_and_title(item) }
        },
        total_item: proc { |items|
          items.count
        },
        total_amount: proc { |items|
          items.sum { |item|
            item.experiences.sum { |experience|
              experience.spans.sum { |span|
                (span.amount * (span.progress || 0.0)).to_i_if_whole
              }
            }
          }
        },
        top_rating: proc { |items, number_arg|
          items
            .map { |item| [author_and_title(item), item.rating] }
            .max_by(number_arg || DEFAULT_NUMBER_ARG) { |_title, rating|
              rating || 0
            }
        },
        top_length: proc { |items, number_arg|
          items
            .map { |item|
              # Longest length, or if undefined length then longest experience
              # (code adapted from top_amount below).
              length = item.variants.map(&:length).max ||
                item.experiences.map { |experience|
                  experience.spans.sum { |span|
                    (span.amount * (span.progress || 0.0)).to_i_if_whole
                  }
                }.max

              [author_and_title(item), length]
            }
            .reject { |_title, length| length.nil? }
            .max_by(number_arg || DEFAULT_NUMBER_ARG) { |_title, length|
              length
            }
        },
        top_amount: proc { |items, number_arg|
          items
            .map { |item|
              amount = item.experiences.sum { |experience|
                experience.spans.sum { |span|
                  (span.amount * (span.progress || 0.0)).to_i_if_whole
                }
              }

              [author_and_title(item), amount]
            }
            .reject { |_title, amount| amount.zero? }
            .max_by(number_arg || DEFAULT_NUMBER_ARG) { |_title, amount|
              amount
            }
        },
        top_speed: proc { |items, number_arg|
          items
            .map { |item|
              speed = calculate_speed(item)
              [author_and_title(item), speed] if speed
            }
            .compact
            .max_by(number_arg || DEFAULT_NUMBER_ARG) { |_title, speed_hash|
              speed_hash[:amount] / speed_hash[:days].to_f
            }
        },
        top_experience: proc { |items, number_arg|
          items
            .map { |item|
              experience_count = item
                .experiences
                .count { |experience|
                  experience.spans.all? { _1.progress.to_d == "1.0".to_d }
                }

              [author_and_title(item), [experience_count, item.rating || 0]]
            }
            .max_by(number_arg || DEFAULT_NUMBER_ARG) { |_title, experience_count_and_rating|
              experience_count_and_rating
            }
            .map { |title, (experience_count, _rating)|
              [title, experience_count]
            }
        },
        top_note: proc { |items, number_arg|
          items
            .map { |item|
              notes_word_count = item
                .notes
                .sum { |note|
                  note.content.scan(/[\w[:punct:]]+/).count
                }

              [author_and_title(item), notes_word_count]
            }
            .max_by(number_arg || DEFAULT_NUMBER_ARG) { |_title, notes_word_count|
              notes_word_count
            }
        },
        bottom_rating: proc { |items, number_arg|
          items
            .map { |item| [author_and_title(item), item.rating] }
            .min_by(number_arg || DEFAULT_NUMBER_ARG) { |_title, rating|
              rating || 0
            }
        },
        bottom_length: proc { |items, number_arg|
          items
            .map { |item|
              # Longest length, or if undefined length then longest experience
              # (code adapted from bottom_amount below).
              length = item.variants.map(&:length).max ||
                item.experiences.map { |experience|
                  experience.spans.sum { |span|
                    (span.amount * (span.progress || 0.0)).to_i_if_whole
                  }
                }.max

              [author_and_title(item), length]
            }
            .reject { |_title, length| length.nil? }
            .min_by(number_arg || DEFAULT_NUMBER_ARG) { |_title, length|
              length
            }
        },
        bottom_amount: proc { |items, number_arg|
          items
            .map { |item|
              amount = item.experiences.sum { |experience|
                experience.spans.sum { |span|
                  (span.amount * (span.progress || 0.0)).to_i_if_whole
                }
              }

              [author_and_title(item), amount]
            }
            .reject { |_title, amount| amount.zero? }
            .min_by(number_arg || DEFAULT_NUMBER_ARG) { |_title, amount|
              amount
            }
        },
        bottom_speed: proc { |items, number_arg|
          items
            .map { |item|
              speed = calculate_speed(item)
              [author_and_title(item), speed] if speed
            }
            .compact
            .min_by(number_arg || DEFAULT_NUMBER_ARG) { |_title, speed_hash|
              speed_hash[:amount] / speed_hash[:days].to_f
            }
        },
        debug: proc { |items|
          items
        },
      }

      ALIASES = {
        average_rating: %w[ar],
        average_length: %w[al],
        average_amount: %w[aia ai],
        :"average_daily-amount" => %w[ada ad],
        list_item: %w[li list],
        total_item: %w[item count],
        total_amount: %w[amount],
        top_rating: %w[tr],
        top_length: %w[tl],
        top_amount: %w[ta],
        top_speed: %w[ts],
        top_experience: %w[te],
        top_note: %w[tn],
        bottom_rating: %w[br],
        bottom_length: %w[bl],
        bottom_amount: %w[ba],
        bottom_speed: %w[bs],
        debug: %w[d],
      }

      REGEXES = ACTIONS.map { |key, _action|
        first_word, second_word = key.to_s.split("_")
        aliases = ALIASES.fetch(key)

        regex =
          %r{
            (
              \A
              \s*
              #{first_word}
              s?
              \s*
              (?<number_arg>
                \d+
              )?
              \s*
              (
                #{second_word}
                s?
              )
              \s*
            )
            |
            (
              \A
              \s*
              (#{aliases.join("|")})
              s?
              \s*
              (?<number_arg>
                \d+
              )?
              \s*
            )
          }x

        [key, regex]
      }.to_h

      # Sums the given Items' amounts per date.
      # @param items [Array<Item>]
      # @return [Hash{Date => Numeric, Reading::Item::TimeLength}]
      private_class_method def self.calculate_amounts_by_date(items)
        amounts_by_date = {}

        items.each do |item|
          item.experiences.each do |experience|
            experience.spans.each do |span|
              next unless span.dates

              dates = span.dates.begin..(span.dates.end || Date.today)

              amount = span.amount / dates.count.to_f
              progress = span.members.include?(:progress) ? span.progress : 1.0

              dates.each do |date|
                amounts_by_date[date] ||= 0
                amounts_by_date[date] += amount * progress
              end
            end
          end
        end

        amounts_by_date
      end

      # Calculates an Item's speed (total amount over how many days). Returns
      # nil if a speed is not able to be calculated (e.g. in a planned Item).
      # @param item [Item]
      # @return [Array(String, Hash), nil]
      private_class_method def self.calculate_speed(item)
        speeds = item.experiences.map { |experience|
          spans_with_finite_dates = experience.spans.reject { |span|
            span.dates.nil? || span.dates.end.nil?
          }
          next unless spans_with_finite_dates.any?

          amount = spans_with_finite_dates.sum { |span|
            # Conditional in case Item was created with fragmentary experience hashes,
            # as in stats_test.rb
            progress = span.members.include?(:progress) ? span.progress : 1.0

            span.amount * progress
          }
          .to_i_if_whole

          days = spans_with_finite_dates.sum { |span| span.dates.count }.to_i

          { amount:, days: }
        }
        .compact

        return nil unless speeds.any?

        speeds.max_by { |hash| hash[:amount] / hash[:days].to_f }
      end

      # A shorter version of Item::View#name.
      # @param item [Item]
      # @return [String]
      private_class_method def self.author_and_title(item)
        "#{item.author + " – " if item.author}#{item.title}"
      end
    end
  end
end
