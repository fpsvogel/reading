# Shortcuts for String#sub and String#gsub replacing with an empty string.
class String
  def remove(pattern)
    sub(pattern, "")
  end

  def remove!(pattern)
    sub!(pattern, "")
  end

  def remove_all(pattern)
    gsub(pattern, "")
  end

  def remove_all!(pattern)
    gsub!(pattern, "")
  end
end
