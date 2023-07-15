require 'pastel'

module Reading
  module Stats
    module ResultFormatters
      TERMINAL = {
        average_length: ->(result) { length_to_s(result) },
        average_amount: ->(result) { length_to_s(result) },
        :'average_daily-amount' => ->(result) { "#{length_to_s(result)} per day" },
        total_item: ->(result) {
          if result.zero?
            PASTEL.bright_black("none")
          else
            color("#{result} #{result == 1 ? "item" : "items"}")
          end
        },
        total_amount: ->(result) { length_to_s(result) },
        top_length: ->(result) { top_or_bottom_lengths(result) },
        top_amount: ->(result) { top_or_bottom_lengths(result) },
        top_speed: ->(result) { top_or_bottom_speeds(result) },
        bottom_length: ->(result) { top_or_bottom_lengths(result) },
        botom_amount: ->(result) { top_or_bottom_lengths(result) },
        bottom_speed: ->(result) { top_or_bottom_speeds(result) },
      }

      private

      PASTEL = Pastel.new

      # Applies a terminal color.
      # @param string [String]
      # @return [String]
      private_class_method def self.color(string)
        PASTEL.bright_blue(string)
      end

      # Converts a length/amount (pages or time) into a string.
      # @param length [Numeric, Reading::Item::TimeLength]
      # @param color [Boolean] whether a terminal color should be applied.
      # @return [String]
      private_class_method def self.length_to_s(length, color: true)
        if length.is_a?(Numeric)
          length_string = "#{length.round} pages"
        else
          length_string = length.to_s
        end

        color ? color(length_string) : length_string
      end

      # Formats a list of top/bottom length results as a string.
      # @param result [Array]
      # @return [String]
      private_class_method def self.top_or_bottom_lengths(result)
        offset = result.count.digits.count

        result
          .map.with_index { |(title, length), index|
            pad = ' ' * (offset - (index + 1).digits.count)

            title_line = "#{index + 1}. #{pad}#{title}"
            indent = "    #{' ' * offset}"

            "#{title_line}\n#{indent}#{length_to_s(length)}"
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
            amount = length_to_s(hash[:amount], color: false)
            days = "#{hash[:days]} #{hash[:days] == 1 ? "day" : "days"}"
            pad = ' ' * (offset - (index + 1).digits.count)

            title_line = "#{index + 1}. #{pad}#{title}"
            indent = "    #{' ' * offset}"
            colored_speed = color("#{amount} in #{days}")

            "#{title_line}\n#{indent}#{colored_speed}"
          }
          .join("\n")
      end
    end
  end
end