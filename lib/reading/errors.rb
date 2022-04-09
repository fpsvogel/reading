require "pastel"

module Reading
  Colors = Pastel.new

  # NotInitializedError indicates that an object has not been initialized before
  # its attempted use.
  class NotInitializedError < StandardError; end

  class AppError < StandardError
    def initialize(msg = nil, label: "Error")
      super(label + colon_before?(msg) + (msg || ""))
    end

    # source is e.g. the CSV line where an invalid Item comes from.
    def handle(source: nil, config:)
      handle = config.fetch(:errors).fetch(:handle_error)
      if source.nil?
        handle.call(self)
      else
        handle.call(styled_with_source(source, config: config))
      end
    end

    protected

    def color
      :red
    end

    def colon_before?(msg)
      msg.nil? ? "" : ": "
    end

    def styled_with_source(source, config:)
      truncated_source = truncate(source,
                                  config.fetch(:errors).fetch(:max_length),
                                  padding: message.length)
      self.class.new(truncated_source,
                      label: styled(message, config))
    end

    def truncate(str, max, padding: 0, min: 30)
      end_index = max - padding
      end_index = min if end_index < min
      str.length + padding > max ? "#{str[0...end_index]}..." : str
    end

    def styled(str, config)
      case config.fetch(:errors).fetch(:style_mode)
      when :terminal
        Colors.send("bright_#{color}").bold(str)
      when :html
        "<rl-error class=\"#{color}\">#{str}</rl-error>"
      end
    end
  end

  module Warning
    def color
      :yellow
    end
  end

  # MISC. ERRORS # # # # # # # # # # # # # # # # # # # # # # # # # #

  class ConfigError < AppError; end

  class InputError < AppError; end

  class OutputError < AppError; end

  # FILE # # # # # # # # # # # # # # # # # # # # # # # # # #

  class FileError < AppError; end

  # InvalidLineError indicates that a line cannot be parsed.
  class InvalidLineError < FileError; end # TODO # RM

  # VALIDATION # # # # # # # # # # # # # # # # # # # # # # # # # #

  # InvalidItemError indicates that data for a new Item is invalid.
  class InvalidItemError < AppError; end

  # InvalidDateError indicates that a date is unparsable, or a set of dates does
  # not make logical sense.
  class InvalidDateError < InvalidItemError
    def initialize(line = nil, label: nil)
      super(line, label: label || "Invalid line (invalid dates):")
    end
  end

  # BlankAttribute is for the errors and warnings below, which indicate that a attribute
  # is blank in data for a new Item.
  module BlankAttribute
    attr_reader :attributes
    def initialize(line_or_attribute = nil, label: nil)
      line, label = from(line_or_attribute, label)
      super(line, label: label)
    end

    private

    def from(line_or_attribute, label)
      if line_or_attribute.is_a?(Array)
        label = "Missing #{line_or_attribute.join(", ")}:"
      else
        line = line_or_attribute
      end
      [line, label]
    end
  end

  class BlankAttributeError < InvalidItemError
    include BlankAttribute
  end

  class BlankAttributeWarning < InvalidItemError
    include BlankAttribute
    include Warning
  end

  # ITEM # # # # # # # # # # # # # # # # # # # # # # # # # #

  # ConsolidatedItemError indicates that an item is expected to have been split
  # by Experience (rereads) but is still consolidated, with multiple Experiences.
  class ConsolidatedItemError < AppError
    def message
      "Cannot get singular Experience data from a consolidated Item (having multiple Experiences)"
    end
  end
end
