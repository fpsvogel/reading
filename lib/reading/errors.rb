require "pastel"

module Reading
  # The base error class, which provides flexible error handling.
  class Error < StandardError
    using Util::StringTruncate

    # Handles this error based on config settings, and augments the error message
    # with styling and the line from the file. All this is handled here so that
    # the parser doesn't have to know all these things at the error's point of origin.
    # @param line [Reading::Line] the CSV line, through which the CSV config and
    #   line string are accessed.
    def handle(line:)
      errors_config = line.csv.config.fetch(:errors)
      styled_error = styled_with_line(line.string, errors_config)

      handle = errors_config.fetch(:handle_error)
      handle.call(styled_error)
    end

    protected

    # Can be overridden in subclasses, e.g. yellow for a warning.
    def color
      :red
    end

    # Creates a new error having a message augmented with styling and the line string.
    # @return [AppError]
    def styled_with_line(line_string, errors_config)
      truncated_line = line_string.truncate(
        errors_config.fetch(:max_length),
        padding: message.length,
      )

      styled_message = case errors_config.fetch(:styling)
        when :terminal
          COLORS.send("bright_#{color}").bold(message)
        when :html
          "<rl-error class=\"#{color}\">#{message}</rl-error>"
        end

      self.class.new("#{styled_message}: #{truncated_line}")
    end

    private

    COLORS = Pastel.new
  end

  # FILE # # # # # # # # # # # # # # # # # # # # # # # # # #

  # Means there was a problem accessing a file.
  class FileError < Reading::Error; end

  # MISC # # # # # # # # # # # # # # # # # # # # # # # # # #

  # Means the user-supplied custom config is invalid.
  class ConfigError < Reading::Error; end

  # VALIDATION # # # # # # # # # # # # # # # # # # # # # # #

  # Means a date is unparsable, or a set of dates does not make logical sense.
  class InvalidDateError < Reading::Error; end

  # Means something in the Source column is invalid.
  class InvalidSourceError < Reading::Error; end

  # Means something in the Head column (author, title, etc.) is invalid.
  class InvalidHeadError < Reading::Error; end

  # Means the Rating column can't be parsed as a number.
  class InvalidRatingError < Reading::Error; end

  # Means a valid length is missing.
  class InvalidLengthError < Reading::Error; end
end
