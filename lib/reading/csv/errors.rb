# frozen_string_literal: true

require_relative "util"

module Readstat
  # NotInitializedError indicates that an object has not been initialized before
  # its attempted use.
  class NotInitializedError < StandardError; end

  class AppError < StandardError
    def initialize(msg = nil, label: "Error:")
      super(color.call(label) +
        space_before?(msg) +
        (msg || ""))
    end

    def show
      puts self
    end

    protected

    def space_before?(msg)
      msg.nil? ? "" : " "
    end

    def color
      Colors.bright_red.bold.detach
    end
  end

  module Warning
    def color
      Colors.bright_yellow.detach
    end
  end

  # MISC. ERRORS # # # # # # # # # # # # # # # # # # # # # # # # # #

  class ConfigError < AppError; end

  class InputError < AppError; end

  class OutputError < AppError; end

  # FILE # # # # # # # # # # # # # # # # # # # # # # # # # #

  class FileError < AppError; end

  # InvalidLineError indicates that a line cannot be parsed.
  class InvalidLineError < FileError
    def initialize(line = nil)
      super(line, label: "Invalid line!")
    end
  end

  # VALIDATION # # # # # # # # # # # # # # # # # # # # # # # # # #

  # ValidationError indicates that data for a new Item is invalid.
  class ValidationError < AppError
    def initialize(line = nil, label: nil)
      super(line, label: label || "Invalid line:")
    end
  end

  # InvalidDateError indicates that a date is unparsable, or a set of dates does
  # not make logical sense.
  class InvalidDateError < ValidationError
    def initialize(line = nil, label: nil)
      super(line, label: label || "Invalid line (invalid dates):")
    end
  end

  # BlankField is for the errors and warnings below, which indicate that a field
  # is blank in data for a new Item.
  module BlankField
    attr_reader :fields
    def initialize(line_or_field = nil, label: nil)
      line, label = from(line_or_field, label)
      super(line, label: label)
    end

    private

    def from(line_or_field, label)
      if line_or_field.is_a?(Array)
        label = "Missing #{line_or_field.join(", ")}:"
      else
        line = line_or_field
      end
      [line, label]
    end
  end

  class BlankFieldError < ValidationError
    include BlankField
  end

  class BlankFieldWarning < ValidationError
    include BlankField
    include Warning
  end

  # ITEM # # # # # # # # # # # # # # # # # # # # # # # # # #

  # ConsolidatedItemError indicates that an item is expected to have been split
  # by Perusal (rereads) but is still consolidated, with multiple Perusals.
  class ConsolidatedItemError < AppError
    def message
      "Cannot get singular Perusal data from a consolidated Item (having multiple Perusals)"
    end
  end
end
