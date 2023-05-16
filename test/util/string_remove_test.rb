require_relative "../test_helpers/test_helper"

class StringRemoveTest < Minitest::Test
  using Reading::Util::StringRemove

  def test_nothing_to_remove
    str = "testing testing 123"

    assert_equal str, str.remove("random string")
  end

  def test_remove
    str = "testing testing 123"

    assert_equal "testing 123", str.remove("testing ")
  end

  def test_remove_all
    str = "testing testing 123"

    assert_equal "123", str.remove_all("testing ")
  end

  def test_remove!
    str = "testing testing 123"

    str.remove!("testing ")

    assert_equal "testing 123", str
  end

  def test_remove_all!
    str = "testing testing 123"

    str.remove_all!("testing ")

    assert_equal "123", str
  end
end
