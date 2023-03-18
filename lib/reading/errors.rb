module Reading
  # Means there was a problem accessing a file.
  class FileError < StandardError; end

  # Means unexpected input was encountered during parsing.
  class ParsingError < StandardError; end

  # # Means there are too many columns in a row.
  # class TooManyColumnsError < StandardError; end

  # # Means the Head column is missing or empty.
  # class MissingHeadError < StandardError; end

  # Means a date is unparsable, or a set of dates does not make logical sense.
  class InvalidDateError < StandardError; end
end
