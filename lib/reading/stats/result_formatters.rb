require "pastel"

module Reading
  module Stats
    module ResultFormatters
      TRUNCATED_TITLES = {
        top_length: ->(result) { with_truncated_title(result) },
        top_amount: ->(result) { with_truncated_title(result) },
        top_speed: ->(result) { with_truncated_title(result) },
        top_experience: ->(result) { with_truncated_title(result) },
        top_note: ->(result) { with_truncated_title(result) },
        bottom_length: ->(result) { with_truncated_title(result) },
        botom_amount: ->(result) { with_truncated_title(result) },
        bottom_speed: ->(result) { with_truncated_title(result) },
      }

      TERMINAL = {
        average_length: ->(result) { color length_to_s(result) },
        average_amount: ->(result) { color length_to_s(result) },
        :"average_daily-amount" => ->(result) { color "#{length_to_s(result)} per day" },
        total_item: ->(result) {
          if result.zero?
            PASTEL.bright_black("none")
          else
            color "#{result} #{result == 1 ? "item" : "items"}"
          end
        },
        total_amount: ->(result) { color length_to_s(result) },
        top_rating: ->(result) { top_or_bottom_numbers_string(result, noun: "star") },
        top_length: ->(result) { top_or_bottom_lengths_string(result) },
        top_amount: ->(result) { top_or_bottom_lengths_string(result) },
        top_speed: ->(result) { top_or_bottom_speeds_string(result) },
        top_experience: ->(result) { top_or_bottom_numbers_string(result, noun: "experience") },
        top_note: ->(result) { top_or_bottom_numbers_string(result, noun: "word") },
        bottom_rating: ->(result) { top_or_bottom_numbers_string(result, noun: "star") },
        bottom_length: ->(result) { top_or_bottom_lengths_string(result) },
        botom_amount: ->(result) { top_or_bottom_lengths_string(result) },
        bottom_speed: ->(result) { top_or_bottom_speeds_string(result) },
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
      private_class_method def self.length_to_s(length)
        if length.nil? || length.zero?
          "nothing"
        elsif length.is_a?(Numeric)
          "#{length.round} pages"
        else
          length.to_s
        end
      end

      # Formats a list of top/bottom length results as a string.
      # @param result [Array]
      # @return [String]
      private_class_method def self.top_or_bottom_lengths_string(result)
        result
          .map { |title, length| "#{title}\n  #{color length_to_s(length)}" }
          .join("\n")
      end

      # Formats a list of top/bottom speed results as a string.
      # @param result [Array]
      # @return [String]
      private_class_method def self.top_or_bottom_speeds_string(result)
        result
          .map { |title, hash|
            amount = length_to_s(hash[:amount])
            days = "#{hash[:days]} #{hash[:days] == 1 ? "day" : "days"}"
            colored_speed = color "#{amount} in #{days}"

            "#{title}\n  #{colored_speed}"
          }
          .join("\n")
      end

      # Formats a list of top/bottom number results as a string.
      private_class_method def self.top_or_bottom_numbers_string(result, noun:)
        result
          .map { |title, number|
            number_string = color "#{number} #{number == 1 ? noun : "#{noun}s"}"

            "#{title}\n  #{number_string}"
          }
          .join("\n")
      end

      # Truncates the title of each result to a specified length.
      # @param result [Array]
      # @param length [Integer] the maximum length of the title.
      # @return [Array]
      private_class_method def self.with_truncated_title(result, length: 45)
        result.map do |title, value|
          truncated_title =
            if title.length + 1 > length
              "#{title[0...length]}…"
            else
              title
            end

          [truncated_title, value]
        end
      end
    end
  end
end