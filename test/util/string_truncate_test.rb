require_relative "../test_helpers/test_helper"

class StringTruncateTest < Minitest::Test
  using Reading::Util::StringTruncate

  def test_truncate_to_max
    str = "a string that is way too long"
    truncated = "a string t..." # 10 characters + "..."

    assert_equal truncated, str.truncate(10)
  end

  def test_max_is_greater_than_length
    str = "a string that is way too long"

    assert_equal str, str.truncate(100)
  end

  def test_max_is_slightly_less_than_length
    str = "a string that is way too long" # 29 characters

    # does not become "a string that is way too l..."
    assert_equal str, str.truncate(26)
  end
end
