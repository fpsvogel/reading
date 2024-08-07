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

        split_input[1..].each do |filter_input|
          match_found = false

          REGEXES.each do |key, regex|
            match = filter_input.match(regex)

            if match
              match_found = true

              begin
                filtered_items = filter_single(
                  key,
                  match[:predicate],
                  match[:operator],
                  filtered_items,
                )
              rescue InputError => e
                raise InputError, "#{e.message} in \"#{input}\""
              end
            end
          end

          unless match_found
            raise InputError, "Invalid filter \"#{filter_input}\" in \"#{input}\""
          end
        end

        filtered_items
      end

      private

      INPUT_SPLIT = /\s+(?=[\w\-]+\s*(?:!=|=|!~|~|>=|>|<=|<))/

      DATES_REGEX = %r{\A
        (?<start_year>\d{4})
        (
          \/
          (?<start_month>\d\d?)
        )?
        (
          -
          (
            (?<end_year>\d{4})
          )?
          \/?
          (?<end_month>\d\d?)?
        )?
      \z}x

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
            if value
              Integer(value, exception: false) ||
                Float(value, exception: false) ||
                (raise InputError, "Rating must be a number")
            end
          }

          positive_operator = operator == :"!=" ? :== : operator

          matches = items.select { |item|
            ratings.any? { |rating|
              if item.rating || %i[== !=].include?(operator)
                item.rating.send(positive_operator, rating)
              end
            }
          }

          # Instead of using item.rating.send(operator, format) above, invert
          # the matches here to ensure multiple values after a negative operator
          # have an "and" relation: "not(x and y)", rather than "not(x or y)".
          if operator == :"!="
            matches = items - matches
          end

          matches
        },
        progress: proc { |values, operator, items|
          progresses = values.map { |value|
            value = "0%" if value == "0"
            match = value.match(/\A(\d+)?%/)

            (match && match.captures.first.to_f.clamp(0.0, 100.0) / 100) ||
              (raise InputError, "Progress must be a percentage")
          }

          filtered_items = items.map { |item|
            # Ensure multiple values after a negative operator have an "and"
            # relation: "not(x and y)", rather than "not(x or y)".
            if operator == :"!="
              item_progresses = item.experiences.map { |experience|
                experience.spans.last.progress || 0.0
              }

              next if (item_progresses - progresses).empty?
            end

            # Filter out non-matching experiences.
            # TODO: Make this more accurate by calculating the average progress
            # across spans? Currently it checks just the last span's progress.
            filtered_experiences = item.experiences.select { |experience|
              progresses.any? { |progress|
                experience.spans.any? &&
                  (experience.spans.last.progress || 0.0).send(operator, progress)
              }
            }

            item.with_experiences(filtered_experiences) if filtered_experiences.any?
          }
          .compact

          filtered_items
        },
        format: proc { |values, operator, items|
          formats = values.map { _1.to_sym if _1 }

          filtered_items = items.map { |item|
            # Treat empty variants as if they were a variant with a nil format.
            if item.variants.empty?
              if operator == :"!="
                next item unless formats.include?(nil)
              else
                next item if formats.include?(nil)
              end
            end

            # Ensure multiple values after a negative operator have an "and"
            # relation: "not(x and y)", rather than "not(x or y)".
            if operator == :"!="
              item_formats = item.variants.map(&:format)

              next if (item_formats - formats).empty?
            end

            # Filter out non-matching variants.
            filtered_variants = item.variants.select { |variant|
              formats.any? { |format|
                variant.format.send(operator, format)
              }
            }

            item.with_variants(filtered_variants) if filtered_variants.any?
          }
          .compact

          filtered_items
        },
        author: proc { |values, operator, items|
          authors = values
            .map { _1.downcase if _1 }
            .map { _1.gsub(/[^a-zA-Z ]/, "").gsub(/\s/, "") if _1 }

          matches = items.select { |item|
            author = item
              &.author
              &.downcase
              &.gsub(/[^a-zA-Z ]/, "")
              &.gsub(/\s/, "")

            if %i[include? exclude?].include? operator
              authors.any? {
                if _1.nil?
                  _1 == author
                else
                  author.include?(_1) if author
                end
              }
            else
              authors.any? { author == _1 }
            end
          }

          if %i[!= exclude?].include? operator
            matches = items - matches
          end

          matches
        },
        title: proc { |values, operator, items|
          titles = values
            .map(&:downcase)
            .map { _1.gsub(/[^a-zA-Z0-9 ]|\ba\b|\bthe\b/, "").gsub(/\s/, "") }

          matches = items.select { |item|
            next unless item.title

            title = item
              .title
              .downcase
              .gsub(/[^a-zA-Z0-9 ]|\ba\b|\bthe\b/, "")
              .gsub(/\s/, "")

            if %i[include? exclude?].include? operator
              titles.any? { title.include? _1 }
            else
              titles.any? { title == _1 }
            end
          }

          if %i[!= exclude?].include? operator
            matches = items - matches
          end

          matches
        },
        series: proc { |values, operator, items|
          format_name = ->(str) {
            str
              &.downcase
              &.gsub(/[^a-zA-Z0-9 ]|\ba\b|\bthe\b/, "")
              &.gsub(/\s/, "")
          }

          series_names = values.map { format_name.call(_1) }

          filtered_items = items.map { |item|
            # Treat empty variants as if they were a variant with no series.
            if item.variants.empty?
              if %i[!= exclude?].include? operator
                next item unless series_names.include?(nil)
              elsif %i[== include?].include? operator
                next item if series_names.include?(nil)
              end
            end

            item_series_names = item.variants.flat_map { |variant|
              variant.series.map { format_name.call(_1.name) }
            }

            # Ensure multiple values after a negative operator have an "and"
            # relation: "not(x and y)", rather than "not(x or y)".
            if %i[!= exclude?].include? operator
              next if operator == :"!=" && (item_series_names - series_names).empty?
              next if operator == :exclude? &&
                item_series_names.all? { |item_series_name|
                  series_names.any? { |series_name|
                    if series_name.nil?
                      item_series_name == series_name
                    else
                      item_series_name.include?(series_name)
                    end
                  }
                }
            end

            # Filter out non-matching variants.
            filtered_variants = item.variants.select { |variant|
              # Treat empty series as if they were a series with a nil name.
              if variant.series.empty?
                if %i[!= exclude?].include? operator
                  next variant unless series_names.include?(nil)
                elsif %i[== include?].include? operator
                  next variant if series_names.include?(nil)
                end
              end

              variant.series.any? { |series|
                item_series_name = format_name.call(series.name)

                series_names.any? {
                  if _1.nil?
                    nil_operator = { include?: :==, exclude?: :"!=" }[operator]
                  end

                  item_series_name.send(nil_operator || operator, _1)
                }
              }
            }

            item.with_variants(filtered_variants) if filtered_variants.any?
          }
          .compact

          filtered_items
        },
        source: proc { |values, operator, items|
          sources = values.map { _1.downcase if _1 }

          filtered_items = items.map { |item|
            # Treat empty variants as if they were a variant with no sources.
            if item.variants.empty?
              if %i[!= exclude?].include? operator
                next item unless sources.include?(nil)
              elsif %i[== include?].include? operator
                next item if sources.include?(nil)
              end
            end

            item_source_names_and_urls = item.variants.flat_map { |variant|
              variant.sources.map { [_1.name&.downcase, _1.url&.downcase] }
            }

            # Ensure multiple values after a negative operator have an "and"
            # relation: "not(x and y)", rather than "not(x or y)".
            if %i[!= exclude?].include? operator
              remainder_names_and_urls = item_source_names_and_urls.reject { |name, url|
                name_nil_match = name.nil? && url.nil? && sources.include?(name)
                url_nil_match = url.nil? && name.nil? && sources.include?(url)

                (name.nil? ? name_nil_match : sources.include?(name)) ||
                  (url.nil? ? url_nil_match : sources.include?(url))
              }

              next if operator == :"!=" && remainder_names_and_urls.empty?
              next if operator == :exclude? &&
                item_source_names_and_urls.all? { |item_source_name_and_url|
                  sources.any? { |source|
                    item_source_name_and_url.any? {
                      _1.nil? ? _1 == source : _1.include?(source) if source
                    }
                  }
                }
            end

            # Filter out non-matching variants.
            filtered_variants = item.variants.select { |variant|
              # Treat empty sources as if they were a source with a nil name.
              if variant.sources.empty?
                if %i[!= exclude?].include? operator
                  next variant unless sources.include?(nil)
                elsif %i[== include?].include? operator
                  next variant if sources.include?(nil)
                end
              end

              variant.sources.any? { |source|
                sources.any?  {
                  if _1.nil?
                    nil_operator = { include?: :==, exclude?: :"!=" }[operator]
                  end

                  source.name&.downcase&.send(nil_operator || operator, _1) ||
                    source.url&.downcase&.send(nil_operator || operator, _1)
                }
              }
            }

            item.with_variants(filtered_variants) if filtered_variants.any?
          }
          .compact

          filtered_items
        },
        :"end-date" => proc { |values, operator, items|
          end_date_ranges = values.map { |value|
            match = value.match(DATES_REGEX) ||
              (raise InputError,
                "End date must be in yyyy/[mm] format, or a date range " \
                "(yyyy/[mm]-[yyyy]/[mm])")

            start_date = Date.new(
              match[:start_year].to_i,
              match[:start_month]&.to_i || 1,
              1,
            )
            end_date = Date.new(
              match[:end_year]&.to_i || start_date.year,
              match[:end_month]&.to_i || match[:start_month]&.to_i || 12,
              -1
            )

            start_date..end_date
          }

          end_date_ranges.each.with_index do |a, i_a|
            end_date_ranges.each.with_index do |b, i_b|
              next if i_a == i_b

              if b.begin <= a.end && a.begin <= b.end
                raise InputError, "Overlapping date ranges"
              end
            end
          end

          filtered_items = items.map { |item|
            # Ensure multiple values after a negative operator have an "and"
            # relation: "not(x and y)", rather than "not(x or y)".
            if operator == :"!="
              item_end_dates = item.experiences.map(&:last_end_date)

              next if item_end_dates.all? { |item_end_date|
                end_date_ranges.any? { |end_date_range|
                  end_date_range.include? item_end_date
                }
              }
            end

            # Filter out non-matching experiences.
            filtered_experiences = item.experiences.select { |experience|
              end_date_ranges.any? { |end_date_range|
                if %i[== !=].include? operator
                  end_date_range
                    .include?(experience.last_end_date)
                    .send(operator, true)
                elsif %i[< >=].include? operator
                  experience.last_end_date.send(operator, end_date_range.begin)
                elsif %i[> <=].include? operator
                  experience.last_end_date.send(operator, end_date_range.end)
                end
              }
            }

            item.with_experiences(filtered_experiences) if filtered_experiences.any?
          }
          .compact

          filtered_items
        },
        date: proc { |values, operator, items|
          date_ranges = values.map { |value|
            match = value.match(DATES_REGEX) ||
              (raise InputError,
                "Date must be in yyyy/[mm] format, or a date range " \
                "(yyyy/[mm]-[yyyy]/[mm])")

            start_date = Date.new(
              match[:start_year].to_i,
              match[:start_month]&.to_i || 1,
              1,
            )
            end_date = Date.new(
              match[:end_year]&.to_i || start_date.year,
              match[:end_month]&.to_i || match[:start_month]&.to_i || 12,
              -1
            )

            start_date..end_date
          }

          date_ranges.each.with_index do |a, i_a|
            date_ranges.each.with_index do |b, i_b|
              next if i_a == i_b

              if b.begin <= a.end && a.begin <= b.end
                raise InputError, "Overlapping date ranges"
              end
            end
          end

          filtered_items = items.map { |item|
            case operator
            when :==
              split_items = date_ranges.sort_by(&:begin).flat_map { |date_range|
                without_before = item.split(date_range.end.next_day).first
                without_before_or_after = without_before&.split(date_range.begin)&.last

                without_before_or_after
              }
              .compact
            when :"!="
              split_item = item

              date_ranges.each do |date_range|
                before = split_item.split(date_range.begin).first
                after = split_item.split(date_range.end.next_day).last

                split_item = split_item.with_experiences(
                  (before&.experiences || []) +
                  (after&.experiences || [])
                )
              end

              split_items = [split_item]
            when :<=
              split_items = [item.split(date_ranges[0].end.next_day).first]
            when :>=
              split_items = [item.split(date_ranges[0].begin).last]
            when :<
              split_items = [item.split(date_ranges[0].begin).first]
            when :>
              split_items = [item.split(date_ranges[0].end.next_day).last]
            end

            split_items.reduce { |merged, split_item|
              merged.with_experiences(merged.experiences + split_item.experiences)
            }
          }
          .compact

          filtered_items
        },
        experience: proc { |values, operator, items|
          experience_counts = values.map { |value|
            Integer(value, exception: false) ||
              (raise InputError, "Experience count must be an integer")
          }

          positive_operator = operator == :"!=" ? :== : operator

          matches = items.select { |item|
            experience_counts.any? { |experience_count|
              item.experiences.count.send(positive_operator, experience_count)
            }
          }

          if operator == :"!="
            matches = items - matches
          end

          matches
        },
        status: proc { |values, operator, items|
          statuses = values.map { _1.squeeze(" ").gsub(" ", "_").to_sym }

          filtered_items = items.map { |item|
            # Ensure multiple values after a negative operator have an "and"
            # relation: "not(x and y)", rather than "not(x or y)".
            if operator == :"!="
              item_statuses = item.experiences.map(&:status).presence || [:planned]

              next unless (item_statuses - statuses).any?
            end

            # Check for a match on a planned Item (no experiences).
            is_planned = item.experiences.empty?
            next item if is_planned && statuses.include?(:planned)

            # Filter out non-matching experiences.
            filtered_experiences = item.experiences.select { |experience|
              statuses.any? { |status|
                experience.status.send(operator, status)
              }
            }

            item.with_experiences(filtered_experiences) if filtered_experiences.any?
          }
          .compact

          filtered_items
        },
        genre: proc { |values, operator, items|
          genres = values.map { _1 ? _1.split("+").map(&:strip) : [_1] }

          matches = items.select { |item|
            genres.any? { |and_genres|
              # Whether item.genres includes all elements of and_genres.
              (item.genres.sort & and_genres.sort) == and_genres.sort ||
                (item.genres.empty? && genres.include?([nil]))
            }
          }

          if operator == :"!="
            matches = items - matches
          end

          matches
        },
        length: proc { |values, operator, items|
          lengths = values.map { |value|
            if value
              Integer(value, exception: false) ||
                Item::TimeLength.parse(value) ||
                (raise InputError, "Length must be a number of pages or time as hh:mm")
            end
          }

          filtered_items = items.map { |item|
            # Treat empty variants as if they were a variant with a nil length.
            if item.variants.empty?
              if operator == :"!="
                next item unless lengths.include?(nil)
              else
                next item if lengths.include?(nil)
              end
            end

            # Ensure multiple values after a negative operator have an "and"
            # relation: "not(x and y)", rather than "not(x or y)".
            if operator == :"!="
              item_lengths = item.variants.map(&:length)

              next if (item_lengths - lengths).empty?
            end

            # Filter out non-matching variants.
            filtered_variants = item.variants.select { |variant|
              lengths.any? { |length|
                variant.length.send(operator, length)
              }
            }

            item.with_variants(filtered_variants) if filtered_variants.any?
          }
          .compact

          filtered_items
        },
        note: proc { |values, operator, items|
          notes = values
            .map { _1.downcase if _1 }
            .map { _1.gsub(/[^a-zA-Z0-9 ]/, "") if _1 }

          matches = items.select { |item|
            item.notes.any? { |original_note|
              note = original_note
                .downcase
                .gsub(/[^a-zA-Z0-9 ]/, "")

              if %i[include? exclude?].include? operator
                notes.any? { _1.nil? ? note == _1 : note.include?(_1) }
              else
                notes.any? { note == _1 }
              end
            } || (item.notes.empty? && notes.include?(nil))
          }

          if %i[!= exclude?].include? operator
            matches = items - matches
          end

          matches
        },
      }

      NUMERIC_OPERATORS = {
        rating: true,
        progress: true,
        experience: true,
        date: true,
        :"end-date" => true,
        length: true,
      }

      PROHIBIT_INCLUDE_EXCLUDE_OPERATORS = {
        format: true,
        status: true,
        genre: true,
      }

      PROHIBIT_NONE_VALUE = {
        progress: true,
        title: true,
        :"end-date" => true,
        date: true,
        experience: true,
        status: true,
      }

      PROHIBIT_MULTIPLE_VALUES_AFTER_NOT = {
        progress: true,
        title: true,
        :"end-date" => true,
        date: true,
        experience: true,
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
            "\"#{key}\" filter, only #{allowed_operators.join(", ")} allowed"
        end

        operator = operator_str.to_sym
        operator = :== if operator == :"="
        operator = :include? if operator == :~
        operator = :exclude? if operator == :"!~"

        values = predicate
          .split(",")
          .map(&:strip)
          .map { _1.downcase == "none" ? nil : _1 }

        # if values.count > 1 && operator == :"!=" && PROHIBIT_MULTIPLE_VALUES_AFTER_NOT[key]
        # end

        if values.count > 1 && %i[> < >= <=].include?(operator)
          raise InputError, "Multiple values not allowed after the operators >, <, >=, or <="
        end

        if values.include?(nil) && !%i[== != include? exclude?].include?(operator)
          raise InputError,
            "\"none\" can only be used after the operators ==, !=, ~, !~"
        end

        if values.any?(&:nil?) && PROHIBIT_NONE_VALUE[key]
          raise InputError, "The \"#{key}\" filter cannot take a \"none\" value"
        end

        matched_items = ACTIONS[key].call(values, operator, items)
        filtered_items += matched_items

        filtered_items.uniq
      end
    end
  end
end
