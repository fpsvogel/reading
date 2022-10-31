require "pastel"
require_relative "util/deep_fetch"

module Reading
  using Util::DeepFetch

  Colors = Pastel.new

  class AppError < StandardError
    def initialize(msg = nil, label: "Error")
      super(label + colon_before?(msg) + (msg || ""))
    end

    # source is e.g. the CSV row where an invalid Item comes from.
    def handle(source: nil, config:)
      handle = config.deep_fetch(:errors, :handle_error)
      if source.nil?
        handle.call(self)
      else
        handle.call(styled_with_source(source, config:))
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
                                  config.deep_fetch(:errors, :max_length),
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
      case config.deep_fetch(:errors, :styling)
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

  # FILE # # # # # # # # # # # # # # # # # # # # # # # # # #

  class FileError < AppError; end

  # VALIDATION # # # # # # # # # # # # # # # # # # # # # # #

  # InvalidItemError indicates that data for a new item is invalid.
  class InvalidItemError < AppError; end
end
