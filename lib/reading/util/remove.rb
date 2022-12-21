# Shortcuts for String#sub and String#gsub when replacing with an empty string.
class String
  def remove(pattern)
    sub(pattern, EMPTY_STRING)
  end

  def remove!(pattern)
    sub!(pattern, EMPTY_STRING)
  end

  def remove_all(pattern)
    gsub(pattern, EMPTY_STRING)
  end

  def remove_all!(pattern)
    gsub!(pattern, EMPTY_STRING)
  end

  private

  EMPTY_STRING = "".freeze
end
