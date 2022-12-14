require "pastel"
require_relative "util/deep_fetch"

module Reading
  using Util::DeepFetch

  Colors = Pastel.new

  class AppError < StandardError
    def handle(line:)
      handle = line.csv.config.deep_fetch(:errors, :handle_error)
      styled_error = styled_with_line(line)

      handle.call(styled_error)
    end

    protected

    def color
      :red
    end

    def styled_with_line(line)
      truncated_line =
        truncate(
          line.string,
          line.csv.config.deep_fetch(:errors, :max_length),
          padding: message.length,
        )
      self.class.new("#{styled(message, line.csv.config)}: #{truncated_line}")
    end

    def truncate(str, max, padding: 0, min: 30)
      end_index = max - padding
      end_index = min if end_index < min
      str.length + padding > max ? "#{str[0...end_index]}..." : str
    end

    def styled(str, config)
      case config.deep_fetch(:errors, :styling)
      when :terminal
        Colors.send("bright_#{color}").bold(str)
      when :html
        "<rl-error class=\"#{color}\">#{str}</rl-error>"
      end
    end
  end

  # FILE # # # # # # # # # # # # # # # # # # # # # # # # # #

  # Indicates that there was a problem accessing a file.
  class FileError < AppError; end

  # VALIDATION # # # # # # # # # # # # # # # # # # # # # # #

  # General error meaning a CSV row is invalid.
  class InvalidItemError < AppError; end

  # Means a date is unparsable, or a set of dates does not make logical sense.
  class InvalidDateError < InvalidItemError; end
end
