module Reading
  module Stats
    module ResultFormatters
      DEFAULT_RESULT_FORMATTERS = {
        average_length: ->(result) { length_to_s(result) },
        average_amount: ->(result) { "#{length_to_s(result)} per day" },
        total_item: ->(result) { "#{result} #{result == 1 ? "item" : "items"}" },
        total_amount: ->(result) { length_to_s(result) },
        top_length: ->(result) { top_or_bottom_lengths(result) },
        top_speed: ->(result) { top_or_bottom_speeds(result) },
        bottom_length: ->(result) { top_or_bottom_lengths(result) },
        bottom_speed: ->(result) { top_or_bottom_speeds(result) },
      }

      # Converts a length/amount (pages or time) into a string.
      # @param length [Numeric, Reading::Item::TimeLength]
      # @return [String]
      private_class_method def self.length_to_s(length)
        if length.is_a?(Numeric)
          "#{length} pages"
        else
          length.to_s
        end
      end

      # Formats a list of top/bottom length results as a string.
      # @param result [Array]
      # @return [String]
      private_class_method def self.top_or_bottom_lengths(result)
        offset = result.count.digits.count

        result
          .map.with_index { |(title, length), index|
            pad = ' ' * (offset - (index + 1).digits.count)

            "#{index + 1}. #{pad}#{title}\n    #{' ' * offset}#{length_to_s(length)}"
          }
          .join("\n")
      end

      # Formats a list of top/bottom speed results as a string.
      # @param result [Array]
      # @return [String]
      private_class_method def self.top_or_bottom_speeds(result)
        offset = result.count.digits.count

        result
          .map.with_index { |(title, hash), index|
            amount = length_to_s(hash[:amount])
            days = "#{hash[:days]} #{hash[:days] == 1 ? "day" : "days"}"
            pad = ' ' * (offset - (index + 1).digits.count)

            "#{index + 1}. #{pad}#{title}\n    #{' ' * offset}#{amount} in #{days}"
          }
          .join("\n")
      end
    end
  end
end